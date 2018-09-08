var _scannerIsRunning = false;

function checkConfidence(result){
    var countDecodedCodes=0, err=0;
    $.each(result.codeResult.decodedCodes, function(id,error){
        if (error.error!=undefined) {
            countDecodedCodes++;
            err+=parseFloat(error.error);
        }
    });
    if (err/countDecodedCodes < 0.1) {
        $("#scanned_bar_code").text(result.codeResult.code);
        
        if($("#get_barcode_object").length){
            $("#get_barcode_object").show();
            var _href = $("#get_barcode_object").attr("href");
            _href = _href.replace(/placeholder/,result.codeResult.code);
            $("#get_barcode_object").attr("href",_href);
        }
        $(".bar_code:text").each(function(){
            $(this).val(result.codeResult.code);
        });
        
    } else {
       
    }
}

function startScanner() {
    Quagga.init({
        inputStream: {
            name: "Live",
            type: "LiveStream",
            target: document.querySelector('#scanner_container')
        },
        decoder: {
            readers: [
                "code_128_reader",
                "ean_reader",
                "ean_8_reader",
                "code_39_reader",
                "code_39_vin_reader",
                "codabar_reader",
                "upc_reader",
                "upc_e_reader",
                "i2of5_reader"
            ],
            debug: {
                showCanvas: true,
                showPatches: true,
                showFoundPatches: true,
                showSkeleton: true,
                showLabels: true,
                showPatchLabels: true,
                showRemainingPatchLabels: true,
                boxFromPatches: {
                    showTransformed: true,
                    showTransformedBox: true,
                    showBB: true
                }
            }
        },

    }, function (err) {
        if (err) {
            console.log(err);
            return
        }

        console.log("Initialization finished. Ready to start");
        Quagga.start();

        // Set flag to is running
        _scannerIsRunning = true;
    });

    Quagga.onProcessed(function (result) {
        var drawingCtx = Quagga.canvas.ctx.overlay,
        drawingCanvas = Quagga.canvas.dom.overlay;

        if (result) {
            if (result.boxes) {
                drawingCtx.clearRect(0, 0, parseInt(drawingCanvas.getAttribute("width")), parseInt(drawingCanvas.getAttribute("height")));
                result.boxes.filter(function (box) {
                    return box !== result.box;
                }).forEach(function (box) {
                    Quagga.ImageDebug.drawPath(box, { x: 0, y: 1 }, drawingCtx, { color: "green", lineWidth: 2 });
                });
            }

            if (result.box) {
                Quagga.ImageDebug.drawPath(result.box, { x: 0, y: 1 }, drawingCtx, { color: "#00F", lineWidth: 2 });
            }

            if (result.codeResult && result.codeResult.code) {
                Quagga.ImageDebug.drawPath(result.line, { x: 'x', y: 'y' }, drawingCtx, { color: 'red', lineWidth: 3 });
            }
        }
    });

    Quagga.onDetected(function (result) {
        checkConfidence(result);
    });
}


$(document).on('click','#toggle_barcode_scanner',function(){
    if(_scannerIsRunning === false){
        startScanner();
        $("#scan_barcode_instructions").slideDown('fast');
    }
    else{
        Quagga.stop();
        $("#scan_barcode_instructions").slideUp('fast');
        _scannerIsRunning = false;
    }
});

$(document).on('change','#force_show',function(){
   
   var _href = $("#get_barcode_object").attr("href");
   
   var setting = "false";
   
   if($(this).is(':checked')){
    setting = "true"; 
   }
   else{
    setting = "false"
   }

   $("#get_barcode_object").attr('href',_href.replace(/force_show=(true|false)/,"force_show=" + setting ));
});

$(document).on('change','#go_to_next_step',function(){
    var _href = $("#get_barcode_object").attr("href");
   
   var setting = "false";
   
   if($('#go_to_next_step').is(':checked')){
    setting = "true"; 
   }
   else{
    setting = "false"
   }

   $("#get_barcode_object").attr('href',_href.replace(/go_to_next_step=(true|false)/,"go_to_next_step=" + setting ));
});

