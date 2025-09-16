public class SIM_JSONIterable implements Iterable<Object> {
    SIM_JSONIterator jsonIterator;        
    
    public SIM_JSONIterable(SIM_JSONIterator pJsonIterator) {
        this.jsonIterator = pJsonIterator;
    }

    public Iterator<Object> Iterator() {
        return jsonIterator;
    }
}