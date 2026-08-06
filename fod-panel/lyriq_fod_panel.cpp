// Watches sys.fod.hbm (set by the framework on UDFPS pointer events) and
// toggles panel HBM through the stock Moto display panel HAL, mirroring
// stock: finger down -> setMode(HIGH_BRIGHT_FOD), finger up -> setMode(NORMAL).

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <android/binder_ibinder.h>
#include <android/binder_manager.h>
#include <android/binder_parcel.h>
#include <android/binder_status.h>
#include <log/log.h>
#include <sys/system_properties.h>

#define TAG "lyriq-fod-panel"

#define PANEL_SERVICE "com.motorola.hardware.display.panel.IDisplayPanel/default"
#define TXN_SET_MODE 5
#define PANEL_MODE_NORMAL 0
#define PANEL_MODE_HIGH_BRIGHT_FOD 4
#define HBM_PROP "sys.fod.hbm"

static AIBinder* waitPanelService(void) {
    AIBinder* binder = AServiceManager_waitForService(PANEL_SERVICE);
    if (binder == NULL) {
        ALOGE("panel service not found");
    }
    return binder;
}

static void setPanelMode(AIBinder** binder, int32_t mode) {
    for (int attempt = 0; attempt < 2; attempt++) {
        AParcel* in = NULL;
        AParcel* out = NULL;
        binder_status_t status = AIBinder_prepareTransaction(*binder, &in);
        if (status == STATUS_OK) {
            status = AParcel_writeInt32(in, mode);
        }
        if (status == STATUS_OK) {
            status = AIBinder_transact(*binder, TXN_SET_MODE, &in, &out, 0);
        }
        if (in != NULL) {
            AParcel_delete(in);
        }
        if (out != NULL) {
            AParcel_delete(out);
        }
        if (status == STATUS_OK) {
            ALOGD("setMode(%d) ok", mode);
            return;
        }
        ALOGE("setMode(%d) failed: %d", mode, status);
        AIBinder_decStrong(*binder);
        *binder = waitPanelService();
        if (*binder == NULL) {
            return;
        }
    }
}

int main(void) {
    AIBinder* binder = waitPanelService();
    if (binder == NULL) {
        return 1;
    }

    // The property is created lazily on the first finger down.
    const prop_info* pi = NULL;
    while ((pi = __system_property_find(HBM_PROP)) == NULL) {
        usleep(500000);
    }

    uint32_t serial = 0;
    char value[PROP_VALUE_MAX];
    for (;;) {
        uint32_t new_serial = serial;
        if (!__system_property_wait(pi, serial, &new_serial, NULL)) {
            ALOGE("property wait failed");
            return 1;
        }
        serial = new_serial;
        __system_property_read(pi, NULL, value);
        setPanelMode(&binder, atoi(value) != 0 ? PANEL_MODE_HIGH_BRIGHT_FOD
                                               : PANEL_MODE_NORMAL);
    }
}
