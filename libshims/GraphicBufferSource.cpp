// SPDX-FileCopyrightText: The LineageOS Project
// SPDX-License-Identifier: Apache-2.0
//
// Android 16 renamed GraphicBufferSource::getHGraphicBufferProducer() (the
// bufferqueue@2.0 flavor used by A15 codec2 HIDL blobs) to
// getHGraphicBufferProducer_V1_0() and removed the unversioned one.  The
// stock codec2 HIDL blobs still import the old symbol, so restore it with
// A15 semantics on top of the still-exported getIGraphicBufferProducer().
// The A16 framework never calls createInputSurface() on the HIDL c2 service
// (it returns OMITTED), but the symbol must still resolve at load time.

#include <gui/IGraphicBufferProducer.h>
#include <gui/bufferqueue/2.0/B2HGraphicBufferProducer.h>

namespace android {

class GraphicBufferSource {
  public:
    sp<IGraphicBufferProducer> getIGraphicBufferProducer() const;
    sp<::android::hardware::graphics::bufferqueue::V2_0::IGraphicBufferProducer>
    getHGraphicBufferProducer() const;
};

sp<::android::hardware::graphics::bufferqueue::V2_0::IGraphicBufferProducer>
GraphicBufferSource::getHGraphicBufferProducer() const {
    return new ::android::hardware::graphics::bufferqueue::V2_0::utils::
            B2HGraphicBufferProducer(getIGraphicBufferProducer());
}

}  // namespace android
