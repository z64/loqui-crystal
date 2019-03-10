module Loqui
  abstract class Codec
    abstract def decode(payload : Bytes)

    def encode(payload)
      payload.to_slice
    end
  end

  class NoOpCodec < Codec
    def decode(payload : Bytes)
      payload
    end
  end
end
