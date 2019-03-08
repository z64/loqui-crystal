module Loqui::Frame
  def self.from_io(io) : Any
    opcode = Opcode.from_io(io)
    frame_class = case opcode
                  when Opcode::Hello    then Hello
                  when Opcode::HelloAck then HelloAck
                  when Opcode::Ping     then Ping
                  when Opcode::Pong     then Pong
                  when Opcode::Request  then Request
                  when Opcode::Response then Response
                  when Opcode::Push     then Push
                  when Opcode::GoAway   then GoAway
                  when Opcode::Error    then Error
                  else
                    raise "Unknown opcode: #{opcode.inspect}"
                  end
    frame_class.from_io(io)
  end

  enum Opcode : UInt8
    Hello    = 1
    HelloAck = 2
    Ping     = 3
    Pong     = 4
    Request  = 5
    Response = 6
    Push     = 7
    GoAway   = 8
    Error    = 9

    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      value = io.read_bytes(UInt8, format)
      Opcode.new(value)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(self.value, format)
    end
  end

  enum Flags : UInt8
    Uncompressed = 0
    Compressed   = 1

    def self.from_io(io : IO, format = IO::BytesFormat::BigEndian)
      value = io.read_bytes(UInt8, format)
      Flags.new(value)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(self.value, format)
    end
  end

  alias Any = Hello | HelloAck | Ping | Pong | Request | Response | Push | GoAway | Error

  record Hello, flags : Flags, version : UInt8, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      version = io.read_bytes(UInt8, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, version, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Hello, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@version, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record HelloAck, flags : Flags, ping_interval : Time::Span, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      ping_interval = io.read_bytes(UInt32, format).milliseconds
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, ping_interval, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::HelloAck, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@ping_interval.total_milliseconds.to_u32, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record Ping, flags : Flags, sequence_number : UInt32 do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      sequence_number = io.read_bytes(UInt32, format)
      new(flags, sequence_number)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Ping, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@sequence_number, format)
    end
  end

  record Pong, flags : Flags, sequence_number : UInt32 do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      sequence_number = io.read_bytes(UInt32, format)
      new(flags, sequence_number)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Pong, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@sequence_number, format)
    end
  end

  record Request, flags : Flags, sequence_number : UInt32, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      sequence_number = io.read_bytes(UInt32, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, sequence_number, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Request, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@sequence_number, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record Response, flags : Flags, sequence_number : UInt32, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      sequence_number = io.read_bytes(UInt32, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, sequence_number, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Response, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@sequence_number, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record Push, flags : Flags, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Push, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record GoAway, flags : Flags, close_code : UInt16, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      close_code = io.read_bytes(UInt16, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, close_code, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::GoAway, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@close_code, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end

  record Error, flags : Flags, sequence_number : UInt32, error_code : UInt16, payload : Bytes do
    def self.from_io(io : IO, format = IO::ByteFormat::BigEndian)
      flags = io.read_bytes(Flags, format)
      sequence_number = io.read_bytes(UInt32, format)
      error_code = io.read_bytes(UInt16, format)
      payload_size = io.read_bytes(UInt32, format)
      payload = Bytes.new(payload_size)
      io.read(payload)
      new(flags, sequence_number, error_code, payload)
    end

    def to_io(io : IO, format = IO::ByteFormat::BigEndian)
      io.write_bytes(Opcode::Error, format)
      io.write_bytes(@flags, format)
      io.write_bytes(@sequence_number, format)
      io.write_bytes(@error_code, format)
      io.write_bytes(@payload.size.to_u32, format)
      io.write(@payload)
    end
  end
end
