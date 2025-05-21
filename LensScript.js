// CaptureTrigger.js
// Script untuk memicu capture dari Lens ke aplikasi Camera Kit

// Dapatkan semua module yang diperlukan
// @input Component.ScriptComponent apiModule {"label":"API Module (Remote API)"}
// @input Component.ScriptComponent photoTriggerObject {"label":"Objek yang memicu photo saat di-tap"}
// @input Component.ScriptComponent videoTriggerObject {"label":"Objek yang memicu video 10 detik saat di-tap"}

// Referensi ke API Module
var ApiModule = null;

// Inisialisasi script saat mulai
function initialize() {
    if (script.apiModule) {
        ApiModule = script.apiModule.api;
        print("API Module loaded successfully");
    } else {
        print("ERROR: API Module tidak ditemukan, tambahkan Remote API Module ke scene");
        return;
    }
    
    // Tambahkan event listener untuk tap pada photoTriggerObject
    if (script.photoTriggerObject) {
        var photoTapEvent = script.createEvent("TapEvent");
        photoTapEvent.bind(function() {
            triggerPhotoCapture();
        });
        script.photoTriggerObject.addEvent(photoTapEvent);
        print("Tap event listener added to photo trigger object");
    }
    
    // Tambahkan event listener untuk tap pada videoTriggerObject
    if (script.videoTriggerObject) {
        var videoTapEvent = script.createEvent("TapEvent");
        videoTapEvent.bind(function() {
            triggerFixedDurationVideo();
        });
        script.videoTriggerObject.addEvent(videoTapEvent);
        print("Tap event listener added to video trigger object");
    }
}

// Fungsi untuk memicu capture foto
function triggerPhotoCapture() {
    if (!ApiModule) {
        print("ERROR: API Module tidak tersedia");
        return;
    }
    
    var data = {
        "type": "photo",
        "app": "firagamirror",
        "timestamp": Date.now()
    };
    
    print("Sending photo capture request to app");
    
    // Panggil API endpoint trigger_capture
    ApiModule.trigger_capture(JSON.stringify(data), function(err, response) {
        if (err) {
            print("Error triggering photo capture: " + err);
            return;
        }
        
        print("Photo capture request sent successfully");
        print("Response: " + JSON.stringify(response));
    });
}

// Fungsi untuk memicu perekaman video dengan durasi tetap (10 detik)
function triggerFixedDurationVideo() {
    if (!ApiModule) {
        print("ERROR: API Module tidak tersedia");
        return;
    }
    
    var data = {
        "type": "video",
        "app": "firagamirror",
        "timestamp": Date.now()
    };
    
    print("Sending fixed duration (10s) video recording request to app");
    
    // Panggil API endpoint trigger_capture
    ApiModule.trigger_capture(JSON.stringify(data), function(err, response) {
        if (err) {
            print("Error triggering video recording: " + err);
            return;
        }
        
        print("Video recording request sent successfully");
        print("Response: " + JSON.stringify(response));
        
        // Tampilkan feedback visual ke pengguna bahwa video sedang direkam
        global.tweenManager.startTween(script.videoTriggerObject, "recording_feedback");
    });
}

// Ekspos fungsi agar dapat dipanggil dari script lain atau event
script.api.triggerPhotoCapture = triggerPhotoCapture;
script.api.triggerFixedDurationVideo = triggerFixedDurationVideo;

// Initialize saat script dimulai
initialize(); 