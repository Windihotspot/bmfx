<template>
  <!--begin::Modal - Create account-->
  <div
    class="modal fade"
    id="kt_modal_camera"
    ref="cameraModalRef"
    tabindex="-1"
    aria-hidden="true"
  >
    <!--begin::Modal dialog-->
    <div class="max-w-3xl mx-auto">
      <!-- mw-800px -> max-w-3xl, modal-dialog centered -> mx-auto -->
      <!--begin::Modal content-->
      <div class="bg-white rounded-lg shadow-lg">
        <!--begin::Modal header-->
        <div class="flex items-center justify-between p-4 border-gray-200">
          <!--begin::Title-->
          <!--end::Title-->

          <!--begin::Close data-bs-dismiss="modal"-->
          <div class="cursor-pointer text-gray-600 hover:text-blue-600">
            <!-- btn btn-sm btn-icon btn-active-color-primary -> cursor-pointer and hover styling-->

            <!-- fs-1 -> text-2xl -->
          </div>
          <!--end::Close-->
        </div>
        <!--end::Modal header-->

        <!--begin::Modal body-->
        <div class="p-5 overflow-y-auto">
          <div class="flex flex-wrap">
            <!-- row -> flex flex-wrap -->
            <div v-if="showCameraModal" class="bg-white p-6 w-full max-w-md mx-auto text-center">
              <!-- Camera Stream -->
              <div
                class="w-72 h-72 mx-auto mb-4 rounded-full overflow-hidden bg-gray-100 flex items-center justify-center"
              >
                <video
                  v-show="!imageCaptured"
                  ref="video"
                  autoplay
                  playsinline
                  class="object-cover w-full h-full"
                ></video>
                <img
                  v-show="imageCaptured"
                  :src="capturedImageSrc"
                  alt="Captured"
                  class="object-cover w-full h-full"
                />
              </div>

              <!-- Buttons -->
              <div class="flex justify-center gap-3 mt-6 flex-wrap">
                <v-btn v-show="!imageCaptured" @click.prevent="captureImage" color="primary"
                  >Snap</v-btn
                >
                <v-btn v-show="imageCaptured" @click.prevent="retakeImage" color="primary"
                  >Re-take</v-btn
                >
                <v-btn v-show="imageCaptured" @click.prevent="useImage" color="success"
                  >Use Photo</v-btn
                >
                <v-btn @click.prevent="cancelImageCapture" color="error">Cancel</v-btn>
              </div>
            </div>
          </div>
        </div>
        <!--end::Modal body-->
      </div>
      <!--end::Modal content-->
    </div>
    <!--end::Modal dialog-->
    <!--end::Modal dialog-->
  </div>
  <!--end::Modal - Create project-->
</template>

<script lang="ts" setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'

// Props to show/hide the modal
const props = defineProps({
  showCameraModal: Boolean
})

// Emits to communicate with the parent component
const emit = defineEmits(['update:showCameraModal', 'imageCaptured']) //, 'stopCameraStream'

// Refs for the video and canvas elements
const video = ref(null)
const canvas = ref(null)
const imageCaptured = ref(false)
const capturedImageSrc = ref('')

const cameraModalRef = ref(null)

// Updated method to start the camera stream
async function startCameraStream() {
  try {
    // Prefer the back camera on mobile devices
    const constraints = {
      video: { facingMode: { ideal: 'environment' } }
    }

    const stream = await navigator.mediaDevices.getUserMedia(constraints)

    if (video.value) {
      video.value.srcObject = stream
    }
  } catch (error) {
    console.error('Error starting camera stream:', error)
  }
}

// Method to stop the camera stream
function stopCameraStream() {
  if (video.value && video.value.srcObject) {
    video.value.srcObject.getTracks().forEach((track) => track.stop())
  }
  // // Reset the image captured state
  // imageCaptured.value = false;
  // // Clear the captured image source
  // capturedImageSrc.value = '';
}

function clearImageViewer() {
  emit('update:showCameraModal', false)
}

// Method to capture an image
function captureImage() {
  console.log('starting captureImage ...')
  if (video.value) {
    const canvas = document.createElement('canvas')
    canvas.width = video.value.videoWidth
    canvas.height = video.value.videoHeight
    const context = canvas.getContext('2d')
    if (context) {
      context.drawImage(video.value, 0, 0)
      capturedImageSrc.value = canvas.toDataURL('image/png')
      imageCaptured.value = true
      stopCameraStream() // Optionally stop the camera stream here
    }
  }
}

// Use the captured image
function useImage() {
  stopCameraStream()

  emit('imageCaptured', capturedImageSrc.value)
  emit('update:showCameraModal', false)
  // Reset the image captured state
  imageCaptured.value = false
  // Clear the captured image source
  capturedImageSrc.value = ''
}

// Retake the image
function retakeImage() {
  imageCaptured.value = false
  startCameraStream()
}

// Cancel the image capture
function cancelImageCapture() {
  stopCameraStream()
  // Reset the image captured state
  imageCaptured.value = false
  // Clear the captured image source
  capturedImageSrc.value = ''

  emit('update:showCameraModal', false)
}

function showCapturedImage(imageSrc) {
  if (imageSrc) {
    capturedImageSrc.value = imageSrc
    imageCaptured.value = true
  }
}

// Expose the method to the parent component
defineExpose({ showCapturedImage, stopCameraStream, clearImageViewer })

// Watch for changes to the showCameraModal prop to start/stop camera stream
watch(
  () => props.showCameraModal,
  (newValue) => {
    if (newValue) {
      startCameraStream()
    } else {
      stopCameraStream()
    }
  }
)

// Lifecycle hooks to manage the camera stream
onMounted(() => {
  if (props.showCameraModal) {
    startCameraStream()
  }

  const modalElement = cameraModalRef.value
  if (modalElement) {
    modalElement.addEventListener('hidden.bs.modal', stopCameraStream)
  }
})

onUnmounted(() => {
  stopCameraStream()

  const modalElement = cameraModalRef.value
  if (modalElement) {
    modalElement.removeEventListener('hidden.bs.modal', stopCameraStream)
  }
})
</script>
