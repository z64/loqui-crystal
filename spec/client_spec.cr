require "socket"
require "./spec_helper"

private def with_server
  server = TCPServer.new("localhost", 1337)
  client_socket = TCPSocket.new("localhost", 1337)
  server_socket = server.accept
  yield client_socket, server_socket
  server.close unless server.closed?
end

describe Loqui::Client do
  it "initializes with a session" do
    socket = IO::Memory.new
    session = Loqui::Session.new(socket)
    Loqui::Client.new(session)
  end

  it "sends requests" do
    with_server do |client_socket, server_socket|
      session = Loqui::Session.new(client_socket)
      client = Loqui::Client.new(session)
      client.spawn_read_loop

      spawn do
        2.times do |i|
          i = i.to_u32
          request = Loqui::Frame.from_io(server_socket).as(Loqui::Frame::Request)
          request.sequence_number.should eq i
          request.payload.should eq "hello server".to_slice

          reply = Loqui::Frame::Response.new(:uncompressed, i, "hello client".to_slice)
          reply.to_io(server_socket)
        end
      end

      2.times do |i|
        reply = client.request("hello server")
        reply.should be_a Loqui::Frame::Response
        reply.sequence_number.should eq i
        reply.payload.should eq "hello client".to_slice
      end

      client.session.close
    end
  end

  it "sends pushes" do
    with_server do |client_socket, server_socket|
      session = Loqui::Session.new(client_socket)
      client = Loqui::Client.new(session)

      client.push("hello server")
      request = Loqui::Frame.from_io(server_socket).as(Loqui::Frame::Push)
      request.payload.should eq "hello server".to_slice
      client.session.close
    end
  end

  it "sends ping" do
    with_server do |client_socket, server_socket|
      session = Loqui::Session.new(client_socket)
      client = Loqui::Client.new(session)

      client.ping
      request = Loqui::Frame.from_io(server_socket).as(Loqui::Frame::Ping)
      request.sequence_number.should eq 0
      client.session.close
    end
  end

  it "sends hello" do
    with_server do |client_socket, server_socket|
      session = Loqui::Session.new(client_socket)
      client = Loqui::Client.new(session)

      client.hello("json,msgpack", "snappy,lz4")
      request = Loqui::Frame.from_io(server_socket).as(Loqui::Frame::Hello)
      expected = "json,msgpack|snappy,lz4"
      payload = String.new(request.payload)
      payload.should eq expected
      client.session.close
    end
  end

  it "calls close callback" do
    with_server do |client_socket, server_socket|
      session = Loqui::Session.new(client_socket)
      client = Loqui::Client.new(session)
      client.spawn_read_loop

      close_payload = Bytes.new(sizeof(Int32))
      IO::ByteFormat::BigEndian.encode(400, close_payload)

      called = Channel(Loqui::Frame::GoAway).new
      client.on_close do |frame|
        called.send(frame)
      end

      frame = Loqui::Frame::GoAway.new(:uncompressed, 1000, close_payload)
      frame.to_io(server_socket)

      close_frame = called.receive
      close_frame.should be_a Loqui::Frame::GoAway
      close_frame.close_code.should eq 1000
      close_frame.payload.should eq close_payload
      client.session.close
    end
  end
end
