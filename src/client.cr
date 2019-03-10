require "./frames"
require "./session"
require "./compressor"
require "./codec"

class Loqui::Client
  getter session
  getter codecs

  def self.new(host, port, dns_timeout = nil, connect_timeout = nil)
    socket = TCPSocket.new(host, port, dns_timeout, connect_timeout)
    session = Session.new(socket)
    Client.new(session)
  end

  def self.new(socket : IO)
    session = Session.new(socket)
    Client.new(session)
  end

  # :nodoc:
  def initialize(@session : Session)
    @response_channels = Hash(UInt32, Channel(Frame::Response | Frame::Error)).new
    @flags = Frame::Flags::Uncompressed
    @send_pings = false

    @compressors = Hash(String, Compressor).new(NoOpCompressor.new)
    @compressors["zlib"] = ZlibCompressor.new
    @codecs = Hash(String, Codec).new(NoOpCodec.new)
  end

  def run(encodings, compression_methods)
    hello(encodings, compression_methods)
    hello_ack = @session.read
    raise "Expected HelloAck payload, got: #{hello_ack}" unless hello_ack.is_a?(Frame::HelloAck)

    data = String.new(hello_ack.payload).split('|')
    @session.encoding = data[0]
    @session.compression_method = data[1]
    @session.ping_interval = hello_ack.ping_interval
    @flags = Frame::Flags::Compressed unless data[1].empty?
    @send_pings = true

    spawn_ping_loop
    spawn_read_loop
  end

  # :nodoc:
  def spawn_ping_loop
    spawn do
      while true
        interval = @session.ping_interval || 1.second
        sleep interval
        break if @session.closed
        if @send_pings
          seq = @session.sequence_number.get
          ping_frame = Frame::Ping.new(@flags, seq)
          @session.send(ping_frame)
        end
      end
    end
  end

  # :nodoc:
  def spawn_read_loop
    spawn do
      while true
        frame = @session.read
        handle_frame(frame)
        break if @session.closed
      end
    end
  end

  def hello(encodings, compression_methods)
    payload = "#{encodings}|#{compression_methods}"
    hello_frame = Frame::Hello.new(Frame::Flags::Uncompressed, 1, payload.to_slice)
    @session.send(hello_frame)
  end

  def request(data)
    seq = @session.next_sequence
    payload = selected_codec.encode(data)
    payload = selected_compressor.compress(payload) # TODO: Set compressed flag accordingly
    frame = Frame::Request.new(@flags, seq, payload)
    @session.send(frame)

    reply = wait_response(seq)
    raise "Request failed: #{reply}" if reply.is_a?(Frame::Error)
    reply_data = if reply.flags.compressed?
                   selected_compressor.decompress(reply.payload)
                 else
                   reply.payload
                 end
    selected_codec.decode(reply_data)
  end

  def push(data)
    payload = selected_codec.encode(data)
    frame = Frame::Push.new(@flags, payload)
    @session.send(frame)
  end

  def ping
    seq = @session.sequence_number.get
    frame = Frame::Ping.new(@flags, seq)
    @session.send(frame)
  end

  def on_close(&block : Frame::GoAway ->)
    @go_away_callback = block
  end

  private def wait_response(seq)
    channel = @response_channels[seq] = Channel(Frame::Response | Frame::Error).new
    channel.receive
  end

  private def selected_codec
    codec = @session.encoding || ""
    @codecs[codec]
  end

  private def selected_compressor
    codec = @session.compression_method || ""
    @compressors[codec]
  end

  # :nodoc:
  def handle_frame(frame)
    case frame
    when Frame::Response, Frame::Error
      @response_channels.delete(frame.sequence_number).try do |channel|
        channel.send(frame)
      end
    when Frame::Ping
      seq = @session.sequence_number.get
      pong_frame = Frame::Pong.new(@flags, seq)
      @session.send(pong_frame)
    when Frame::GoAway
      @go_away_callback.try &.call(frame)
      @session.close
    end
  end
end
