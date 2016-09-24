module Braingasm
  describe InputBuffer do
    subject { InputBuffer.new(StringIO.new(@input)) }

    it "provides IO methods #getbyte and #gets, and also allows #ungetc" do
      @input = "hey\nthere"

      expect(subject.getbyte).to be('h'.ord)
      expect(subject.gets).to eq("ey\n")

      subject.ungetc('A')
      expect(subject.getbyte).to be('A'.ord)
      subject.ungetc(66)
      expect(subject.getbyte).to be(66)

      expect(subject.getbyte.chr).to eq('t')
      expect(subject.gets).to eq("here")

      expect(subject.getbyte).to be(nil)
      expect(subject.gets).to be(nil)
    end
  end
end
