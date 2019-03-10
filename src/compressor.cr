require "zlib"

module Loqui
  abstract class Compressor
    abstract def compress(payload : Bytes) : Bytes
    abstract def decompress(payload : Bytes) : Bytes
  end

  class NoOpCompressor < Compressor
    def compress(payload : Bytes)
      payload
    end

    def decompress(payload : Bytes)
      payload
    end
  end

  class ZlibCompressor < Compressor
    def compress(payload : Bytes)
      buffer = IO::Memory.new
      Zlib::Writer.open(buffer) do |writer|
        writer.write(payload)
      end
      buffer.to_slice
    end

    def decompress(payload : Bytes)
      buffer = IO::Memory.new
      Zlib::Reader.open(IO::Memory.new(payload)) do |reader|
        IO.copy(reader, buffer)
      end
      buffer.to_slice
    end
  end
end
