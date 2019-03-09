class Loqui::Session
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
