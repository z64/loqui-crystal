require "./frames"

class Loqui::Client
  class Session
    getter sequence_number : Atomic(UInt32)
    getter closed : Bool
    getter encoding : String? = nil
    getter compression_method : String? = nil

    def initialize(@socket : IO)
      @sequence_number = Atomic(UInt32).new(0_u32)
      @closed = false
    end

    def next_sequence
      @sequence_number.add(1_u32)
    end

    def send(frame)
      frame.to_io(@socket)
    end

    def read
      Frame.from_io(@socket)
    end

    def close
      @socket.close
      @closed = true
    end
  end

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
    @response_channels = Hash(Int32, Channel(Frame::Response | Frame::Error)).new
    @flags = Frame::Flags::Uncompressed
    @send_pings = false
  end

  def run(encodings, compression_methods)
    payload = "#{encodings}|#{compression_methods}"
    hello_frame = Frame::Hello.new(Frame::Flags::Uncompressed, 1, payload.to_slice)
    @session.send(hello_frame)

    hello_ack = @session.read
    raise "Expected HelloAck payload, got: #{hello_ack}" unless hello_ack.is_a?(Frame::HelloAck)

    data = String.new(hello_ack.payload).split('|')
    @session.encoding = data[0]
    @session.compression_method = data[1]
    @session.ping_interval = hello_ack.ping_interval
    @flags = Frame::Flags::Compressed unless data[1].empty?
    @send_pings = true

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

    while true
      frame = @session.read
      handle_frame(frame)
      break if @session.closed
    end
  end

  def request(data) : Frame::Response
    seq = @session.next_sequence
    frame = Frame::Request.new(@flags, seq, data.to_slice)
    @session.send(frame)
    reply = wait_response(seq)
    raise "Request failed: #{reply}" if reply.is_a?(Frame::Error)
    reply
  end

  def push(data)
    frame = Frame::Push.new(@flags, data.to_slice)
    @session.send(frame)
  end

  def ping
    seq = @session.sequence_number.get
    frame = Frame::Ping.new(@flags, seq)
    @session.send(frame)
  end

  private def wait_response(seq)
    channel = @channels[seq] = Channel(Frame::Response | Frame::Error).new
    channel.receive
  end

  # :nodoc:
  def handle_frame(frame)
    case frame
    when Frame::Response, Frame::Error
      @response_channels.delete(frame.seq).try do |channel|
        channel.send(frame)
      end
    when Frame::Ping
      seq = @session.sequence_number.get
      pong_frame = Frame::Pong.new(@flags, seq)
      @session.send(pong_frame)
    when Frame::GoAway
      # TODO: close callback
      @session.close
    end
  end
end
