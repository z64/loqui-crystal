require "./spec_helper"

format = IO::ByteFormat::NetworkEndian

it "reads writes Hello" do
  write_frame = Loqui::Frame::Hello.new(:uncompressed, 1_u8, "foo".to_slice)
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Hello.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes HelloAck" do
  write_frame = Loqui::Frame::HelloAck.new(:uncompressed, 41.25.seconds, "foo".to_slice)
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::HelloAck.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Ping" do
  write_frame = Loqui::Frame::Ping.new(:uncompressed, 1_u32)
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Ping.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Pong" do
  write_frame = Loqui::Frame::Pong.new(:uncompressed, 1_u32)
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Pong.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Request" do
  write_frame = Loqui::Frame::Request.new(:uncompressed, 1_u32, Bytes[1, 2, 3])
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Request.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Response" do
  write_frame = Loqui::Frame::Response.new(:uncompressed, 2_u32, Bytes[1, 2, 3])
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Response.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Push" do
  write_frame = Loqui::Frame::Push.new(:uncompressed, Bytes[1, 2, 3])
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Push.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes GoAway" do
  write_frame = Loqui::Frame::GoAway.new(:uncompressed, 1000_u16, Bytes[1, 2, 3])
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::GoAway.from_io(io)
  read_frame.should eq write_frame
end

it "reads writes Error" do
  write_frame = Loqui::Frame::Error.new(:uncompressed, 3_u32, 400_u16, Bytes[1, 2, 3])
  io = IO::Memory.new
  write_frame.to_io(io)

  io.rewind
  io.skip(sizeof(UInt8))

  read_frame = Loqui::Frame::Error.from_io(io)
  read_frame.should eq write_frame
end
