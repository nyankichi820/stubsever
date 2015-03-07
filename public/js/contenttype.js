var AppBridge = {};

(function(){

    AppBridge.sendClick =  function(x,y){
        var elem = document.elementFromPoint(x, y);
        var evt = document.createEvent( "MouseEvents" ); 
        evt.initEvent( "click", false, true ); 
        elem.dispatchEvent( evt );
    };

})();
