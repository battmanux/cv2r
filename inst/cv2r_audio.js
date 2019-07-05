audioCtx = new AudioContext();
scriptNode = audioCtx.createScriptProcessor(audio_buff_size, 1, 1);
var mp3encoder = new lamejs.Mp3Encoder(1, 44100, 64); 
            
function _arrayBufferToBase64( buffer ) {
    var binary = "";
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

var gFrameOn = 0;

scriptNode.onaudioprocess = function(audioProcessingEvent) {
    arrayBufferIn = audioProcessingEvent.inputBuffer.getChannelData(0);
    arrayBufferOut = audioProcessingEvent.outputBuffer.getChannelData(0)
    
    var min = Math.min.apply(null, arrayBufferIn);
    var max = Math.max.apply(null, arrayBufferIn);
    
    if ( min < 0.1 && max > 0.1 ) {
      gFrameOn = 2;
    }
    
    if ( gFrameOn === 0 ) {
      Shiny.onInputChange(inputId+"_audio", "" );
    }
    else if ( gFrameOn > 0 ) {
      gFrameOn -= 1;
      
       for(var i=0;i<arrayBufferIn.length;i++) {
          arrayBufferIn[i] = arrayBufferIn[i]*32767.5;
      }
      
      var lBuff = [];
      var mp3Tmp = mp3encoder.encodeBuffer(arrayBufferIn); //encode mp3
      lBuff.push(new Int8Array(mp3Tmp) );
      mp3Tmp = mp3encoder.flush();
      lBuff.push(new Int8Array(mp3Tmp) );

      var c = new Int8Array(lBuff[0].length + lBuff[1].length);
      c.set(lBuff[0]);
      c.set(lBuff[1], lBuff[0].length);

      var base64buff = _arrayBufferToBase64(c.buffer);
      Shiny.onInputChange(inputId+"_audio", base64buff );
    }
};
         