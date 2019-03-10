require "./spec_helper"

describe Loqui::ZlibCompressor do
  it "compresses round trip" do
    compressor = Loqui::ZlibCompressor.new
    data = "hello world".to_slice
    compressed = compressor.compress(data)
    decompressed = compressor.decompress(compressed)
    decompressed.should eq data
  end
end
