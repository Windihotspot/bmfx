<template>
  <div v-if="modelValue" class="fixed inset-0 z-[9999] flex items-center justify-center px-4 sm:px-4">
    <!-- BACKDROP -->
    <div class="absolute inset-0 bg-black/45" @click="close"></div>

    <!-- DIALOG -->
    <div
      class="relative w-full max-w-[420px] bg-white rounded-[20px] overflow-hidden shadow-2xl max-h-[95vh] overflow-y-auto"
    >
      <!-- HEADER -->
      <div class="fund-header">
        <div>
          <h2 class="text-white text-[17px] font-bold leading-tight">Fund Wallet</h2>
          <p class="text-white/75 text-[12px] mt-1">Choose an amount and how you'd like to pay</p>
        </div>

        <button type="button" @click="close" class="close-button">
          <i class="mdi mdi-close text-[20px]"></i>
        </button>
      </div>

      <div class="px-6 py-6">
        <!-- AMOUNT -->
        <div class="amount-card">
          <p class="text-[#7c2be8] text-[11px] font-semibold uppercase tracking-wide">
            Amount to fund
          </p>

          <div class="amount-input-wrap">
            <span class="text-[#7c2be8] text-[28px] font-extrabold">$</span>
            <input
              v-model.number="amount"
              type="number"
              min="1"
              step="1"
              inputmode="decimal"
              placeholder="0.00"
              class="amount-input"
            />
          </div>

          <div class="flex flex-wrap gap-2 mt-4">
            <button
              v-for="preset in presets"
              :key="preset"
              type="button"
              @click="amount = preset"
              class="preset-chip"
              :class="{ 'preset-chip-active': amount === preset }"
            >
              ${{ preset.toLocaleString('en-US') }}
            </button>
          </div>

          <p v-if="errorMessage" class="text-[11px] text-rose-500 mt-3" role="alert">
            {{ errorMessage }}
          </p>
        </div>

        <!-- INFO -->
        <div class="info-card">
          <div class="info-icon">ℹ</div>
          <p>
            Your wallet is credited once your payment has been verified. Use your payment
            reference as the note or narration.
          </p>
        </div>

        <!-- PAYMENT METHODS -->
        <p class="text-[12px] font-semibold text-[#241044] mt-5 mb-3">Payment method</p>

        <div class="space-y-3">
          <template v-for="method in methods" :key="method.id">
            <button
              type="button"
              @click="selectMethod(method.id)"
              class="payment-method"
              :class="{ 'payment-method-active': paymentMethod === method.id }"
            >
              <div class="method-icon">
                <i :class="['mdi', method.icon, 'text-[22px]']"></i>
              </div>

              <div class="text-left flex-1">
                <p class="text-[14px] font-bold text-[#241044]">{{ method.label }}</p>
                <p class="text-[11px] text-[#716b86] mt-1">{{ method.hint }}</p>
              </div>

              <i
                :class="
                  paymentMethod === method.id
                    ? 'mdi mdi-chevron-down text-purple-600'
                    : 'mdi mdi-chevron-right text-gray-400'
                "
              ></i>
            </button>

            <!-- METHOD DETAILS -->
            <div v-if="paymentMethod === method.id" class="method-details">
              <!-- Rows of payment details (handle, address, bank info...) -->
              <div v-for="row in method.details" :key="row.label" class="account-row">
                <span>{{ row.label }}</span>

                <div class="flex items-center gap-2">
                  <strong class="break-all">{{ row.value || '—' }}</strong>

                  <button
                    v-if="row.copy && row.value"
                    type="button"
                    @click.stop="copyValue(row.value, method.id + row.label)"
                    class="copy-button"
                  >
                    {{ copiedKey === method.id + row.label ? 'Copied' : 'Copy' }}
                  </button>
                </div>
              </div>

              <!-- Free text for "Other" -->
              <template v-if="method.id === 'other'">
                <label class="block text-[11px] text-[#716b86] mt-1 mb-2">
                  Which method would you like to use?
                </label>
                <input
                  v-model="otherMethod"
                  type="text"
                  placeholder="e.g. Zelle, Apple Cash, USDT"
                  class="other-input"
                />
              </template>

              <!-- Fee / amount summary -->
              <div class="fee-row total-highlight">
                <span class="font-semibold text-[#5C2ECD]">You will send</span>
                <span class="font-bold text-[#6C3EF4]">{{ formatCurrency(amount) }}</span>
              </div>

              <p class="text-[11px] text-[#716b86] leading-5 mt-3">
                Include reference <strong class="text-[#241044]">{{ reference }}</strong>
                with your payment so we can match it to your wallet.
              </p>

              <button type="button" @click="confirmPayment(method)" class="confirm-button">
                I've Made the Payment
              </button>
            </div>
          </template>
        </div>

        <!-- CANCEL -->
        <button type="button" @click="close" class="cancel-button">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },

  // Override with your real payment details, e.g.
  // { paypal: { email: '...' }, venmo: { handle: '...' }, btc: { address: '...', network: 'Bitcoin' },
  //   bank: { bankName: '...', accountName: '...', accountNumber: '...' }, cashapp: { cashtag: '...' } }
  paymentDetails: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue', 'submit'])

const presets = [50, 100, 250, 500, 1000]

const amount = ref(null)
const paymentMethod = ref(null)
const otherMethod = ref('')
const copiedKey = ref('')
const errorMessage = ref('')
const reference = ref('')

const formatCurrency = (value) =>
  `$${Number(value || 0).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })}`

const makeReference = () => `FW-${Date.now().toString(36).toUpperCase().slice(-6)}`

const methods = computed(() => {
  const d = props.paymentDetails
  return [
    {
      id: 'paypal',
      label: 'PayPal',
      hint: 'Send to our PayPal account',
      icon: 'mdi-paypal',
      details: [{ label: 'PayPal Email', value: d.paypal?.email, copy: true }]
    },
    {
      id: 'venmo',
      label: 'Venmo',
      hint: 'Pay to our Venmo handle',
      icon: 'mdi-alpha-v-circle-outline',
      details: [{ label: 'Venmo Handle', value: d.venmo?.handle, copy: true }]
    },
    {
      id: 'btc',
      label: 'Bitcoin (BTC)',
      hint: 'Send BTC to our wallet address',
      icon: 'mdi-bitcoin',
      details: [
        { label: 'Network', value: d.btc?.network || 'Bitcoin' },
        { label: 'Wallet Address', value: d.btc?.address, copy: true }
      ]
    },
    {
      id: 'bank',
      label: 'Bank Transfer',
      hint: 'Transfer to our bank account',
      icon: 'mdi-bank-outline',
      details: [
        { label: 'Bank Name', value: d.bank?.bankName },
        { label: 'Account Name', value: d.bank?.accountName },
        { label: 'Account Number', value: d.bank?.accountNumber, copy: true }
      ]
    },
    {
      id: 'cashapp',
      label: 'Cash App',
      hint: 'Pay to our $Cashtag',
      icon: 'mdi-cash',
      details: [{ label: '$Cashtag', value: d.cashapp?.cashtag, copy: true }]
    },
    {
      id: 'other',
      label: 'Other',
      hint: 'Tell us your preferred method',
      icon: 'mdi-dots-horizontal-circle-outline',
      details: []
    }
  ]
})

const selectMethod = (id) => {
  paymentMethod.value = paymentMethod.value === id ? null : id
  errorMessage.value = ''
}

const copyValue = async (value, key) => {
  try {
    await navigator.clipboard.writeText(value)
    copiedKey.value = key
    setTimeout(() => (copiedKey.value = ''), 2000)
  } catch (error) {
    console.error('Failed to copy:', error)
  }
}

const confirmPayment = (method) => {
  if (!amount.value || amount.value <= 0) {
    errorMessage.value = 'Enter a valid amount to fund.'
    return
  }

  if (method.id === 'other' && !otherMethod.value.trim()) {
    errorMessage.value = 'Tell us which payment method you want to use.'
    return
  }

  emit('submit', {
    amount: Number(amount.value),
    method: method.id,
    methodLabel: method.id === 'other' ? otherMethod.value.trim() : method.label,
    reference: reference.value
  })
}

const close = () => emit('update:modelValue', false)

// Reset every time the dialog opens
watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      amount.value = null
      paymentMethod.value = null
      otherMethod.value = ''
      copiedKey.value = ''
      errorMessage.value = ''
      reference.value = makeReference()
    }
  }
)
</script>

<style scoped>
.fund-header {
  height: 80px;
  padding: 18px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(90deg, #7928df 0%, #e13e9c 100%);
}

.close-button {
  width: 31px;
  height: 31px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.14);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-button:hover {
  background: rgba(255, 255, 255, 0.25);
}

/* AMOUNT */
.amount-card {
  padding: 18px;
  background: linear-gradient(135deg, #f9e9fb 0%, #f7e4f5 100%);
  border: 1px solid #e4b9f2;
  border-radius: 12px;
  text-align: left;
}

.amount-input-wrap {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 14px;
}

.amount-input {
  width: 100%;
  background: transparent;
  outline: none;
  color: #17072e;
  font-size: 32px;
  line-height: 1;
  font-weight: 800;
}

.amount-input::placeholder {
  color: #c9b6e0;
}

.preset-chip {
  padding: 6px 12px;
  border-radius: 999px;
  border: 1px solid #e4b9f2;
  background: white;
  color: #716b86;
  font-size: 12px;
  font-weight: 600;
  transition: all 0.2s ease;
}

.preset-chip:hover,
.preset-chip-active {
  border-color: #7928df;
  background: #7928df;
  color: white;
}

/* INFO */
.info-card {
  margin-top: 20px;
  padding: 12px 14px;
  border: 1px solid #e3dce9;
  border-radius: 11px;
  display: flex;
  align-items: flex-start;
  gap: 8px;
  color: #716b86;
  font-size: 12px;
  line-height: 1.7;
}

.info-icon {
  flex-shrink: 0;
  color: #006fbd;
  font-size: 14px;
}

/* PAYMENT METHODS */
.payment-method {
  width: 100%;
  min-height: 74px;
  padding: 12px 16px;
  border: 1px solid #e2d8ee;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 14px;
  background: white;
  transition: all 0.2s ease;
}

.payment-method:hover,
.payment-method-active {
  border-color: #a965e5;
  background: #fdf8ff;
}

.method-icon {
  width: 44px;
  height: 44px;
  border-radius: 11px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: #f8e7fa;
  color: #241044;
}

/* METHOD DETAILS */
.method-details {
  padding: 15px;
  border: 1px solid #e2d8ee;
  border-top: 0;
  border-radius: 0 0 12px 12px;
  background: #fcfaff;
  margin-top: -13px;
}

.account-row {
  padding: 9px 0;
  border-bottom: 1px solid #eee8f4;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 11px;
}

.account-row span {
  color: #716b86;
  flex-shrink: 0;
}

.account-row strong {
  color: #241044;
  text-align: right;
}

.copy-button {
  color: #7624df;
  font-size: 10px;
  font-weight: 700;
}

.other-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e2d8ee;
  border-radius: 10px;
  background: white;
  font-size: 12px;
  outline: none;
  margin-bottom: 12px;
}

.other-input:focus {
  border-color: #a965e5;
}

.fee-row {
  padding: 10px 12px;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #716b86;
  margin-top: 12px;
}

.fee-row.total-highlight {
  background: #f3f0ff;
  border: 1px solid #c4b5fd;
}

.confirm-button {
  width: 100%;
  height: 42px;
  margin-top: 14px;
  border-radius: 999px;
  background: linear-gradient(90deg, #7928df 0%, #e13e9c 100%);
  color: white;
  font-size: 12px;
  font-weight: 700;
  transition: all 0.2s ease;
}

.confirm-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 16px rgba(124, 43, 232, 0.2);
}

.cancel-button {
  display: block;
  margin: 20px auto 0;
  color: #716b86;
  font-size: 13px;
}

.cancel-button:hover {
  color: #241044;
}
</style>