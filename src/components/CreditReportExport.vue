<template>
  <div ref="pdfContent" class="p-6 space-y-6 bg-white text-gray-800">
    <!-- First Central Section -->
    <h1 class="text-2xl font-bold">First Central</h1>
    <section>
      <div v-if="idType !== 'business'">
        <!-- // personal -->
        <div class="bg-white p-6 rounded space-y-4">
          <h2 class="text-md font-semibold mb-4">Personal details summary</h2>

          <!-- Check if `personal` has any data -->
          <div
            v-if="personal && Object.keys(personal).length > 0"
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-y-6 gap-x-8 text-sm text-gray-600"
          >
            <!-- All your data fields remain unchanged here -->
            <div>
              <p class="mb-1">Last Name</p>
              <p class="font-bold text-gray-900">{{ personal.Surname }}</p>
            </div>
            <div>
              <p class="mb-1">Gender</p>
              <p class="font-bold text-gray-900">{{ personal.Gender }}</p>
            </div>
            <div>
              <p class="mb-1">Phone Number</p>
              <p class="font-bold text-gray-900">{{ personal.CellularNo }}</p>
            </div>
            <div>
              <p class="mb-1">Latest Residential Address</p>
              <p class="font-bold text-gray-900 leading-snug">
                {{ personal.ResidentialAddress1 }}
              </p>
            </div>
            <div>
              <p class="mb-1">First Name</p>
              <p class="font-bold text-gray-900">{{ personal.FirstName }}</p>
            </div>
            <div>
              <p class="mb-1">Bank Verification Number</p>
              <p class="font-bold text-gray-900">{{ personal.BankVerificationNo }}</p>
            </div>
            <div>
              <p class="mb-1">Work Telephone</p>
              <p class="font-bold text-gray-900">{{ personal.WorkTelephoneNo }}</p>
            </div>
            <div>
              <p class="mb-1">Other Names</p>
              <p class="font-bold text-gray-900">{{ personal.OtherNames }}</p>
            </div>
            <div>
              <p class="mb-1">Date of Birth</p>
              <p class="font-bold text-gray-900">{{ personal.BirthDate }}</p>
            </div>
            <div>
              <p class="mb-1">Home Telephone</p>
              <p class="font-bold text-gray-900">{{ personal.HomeTelephoneNo }}</p>
            </div>
          </div>

          <!-- Fallback message if no data -->
          <div v-else class="text-gray-500 text-sm italic">No personal data available.</div>
        </div>
      </div>

      <div v-else>
        <!-- BUSINESS INFORMATION SECTION -->
        <div v-if="idType === 'business'" class="bg-white p-6 rounded space-y-4">
          <h2 class="text-md font-semibold">Business Information</h2>
          <div
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-y-6 gap-x-8 text-sm text-gray-600"
          >
            <div>
              <p class="mb-1">Business Name</p>
              <p class="font-bold text-gray-900">{{ businessData.BusinessName }}</p>
            </div>
            <div>
              <p class="mb-1">Date of Incorporation</p>
              <p class="font-bold text-gray-900">{{ businessData.DateOfIncorporation }}</p>
            </div>
            <div>
              <p class="mb-1">Business Address</p>
              <p class="font-bold text-gray-900">
                {{ businessData.CommercialAddress1 }}, {{ businessData.CommercialAddress2 }},
                {{ businessData.CommercialAddress4 }}
              </p>
            </div>
          </div>
        </div>

        <!-- DIRECTOR INFORMATION TABLE -->
        <div v-if="idType === 'business'" class="bg-white p-6 rounded space-y-4 mt-4">
          <h2 class="text-md font-semibold">Director Information</h2>

          <div v-if="directors.length > 0">
            <table class="min-w-full text-sm text-left">
              <thead class="text-xs font-semibold text-gray-700">
                <tr>
                  <th class="p-2">First Name</th>
                  <th class="p-2">Other Names</th>
                  <th class="p-2">Surname</th>
                  <th class="p-2">Identification Number</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(director, index) in directors" :key="index" class="">
                  <td class="p-2 font-bold text-gray-900">{{ director.firstName }}</td>
                  <td class="p-2 font-bold text-gray-900">{{ director.othernames }}</td>
                  <td class="p-2 font-bold text-gray-900">{{ director.surname }}</td>
                  <td class="p-2 font-bold text-gray-900">
                    {{ director.Identificationnumber }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="text-sm text-gray-500 italic">No director information available.</div>
        </div>
      </div>

      <!-- Summary -->
      <div class="bg-white p-6 rounded-md mt-4">
        <h2 class="text-md font-semibold mb-6">Summary</h2>

        <!-- Show data if summary object exists and is not empty -->
        <div
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-y-6 gap-x-8 text-sm text-gray-600"
        >
          <!-- Row 1 -->
          <div>
            <p class="mb-1">Total active monthly installment</p>
            <p class="font-bold text-gray-900">{{ summary.TotalMonthlyInstalment }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of credit facilities</p>
            <p class="font-bold text-gray-900">{{ fcbcCreditAgreementSummaryCount }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of open facilities</p>
            <p class="font-bold text-gray-900">{{ summary.TotalOpenFacilities }}</p>
          </div>

          <!-- Row 2 -->
          <div>
            <p class="mb-1">Total arrear amount</p>
            <p class="font-bold text-gray-900">{{ summary.Amountarrear }}</p>
          </div>
          <div>
            <p class="mb-1">Total outstanding debts</p>
            <p class="font-bold text-gray-900">{{ summary.TotalOutstandingdebt }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of closed credit facilities</p>
            <p class="font-bold text-gray-900"></p>
          </div>

          <!-- Row 3 -->
          <div>
            <p class="mb-1">Total no of account in arrears</p>
            <p class="font-bold text-gray-900">{{ summary.TotalAccountarrear }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of delinquent facilities</p>
            <p class="font-bold text-gray-900">{{ fcbcHighestDelinquencyRatingCount }}</p>
          </div>
          <div>
            <p class="mb-1">Total no written off facilities</p>
            <p class="font-bold text-gray-900">{{ summary.TotalWrittenOffFacilities }}</p>
          </div>
        </div>

        <!-- Fallback if no data -->
      </div>

      <!-- Loan Accounts Table -->
      <div class="bg-white p-6 rounded">
        <h2 class="text-md font-semibold mb-4">Loan Accounts</h2>

        <div v-if="creditAgreementSummary && creditAgreementSummary.length > 0">
          <v-data-table
            :headers="loanHeaders"
            :items="creditAgreementSummary"
            item-value="uid"
            :expanded.sync="expanded"
            class="elevation-1"
            fixed-header
            height="400"
            hide-default-footer
          >
            <!-- Default item row -->
            <template #item.status="{ item }">
              <v-chip
                :color="getStatusColor(item.status)"
                variant="tonal"
                size="small"
                class="text-white"
              >
                {{ item.status?.trim() || 'Unknown' }}
              </v-chip>
            </template>
            <template #item.action="{ item }">
              <v-btn size="small" color="primary" @click="toggleRow(item.uid)">
                {{ isExpanded(item.uid) ? 'Hide' : 'View' }}
              </v-btn>
            </template>

            <!-- Expanded content -->
            <template #expanded-row="{ item }">
              <td :colspan="loanHeaders.length" class="px-4 py-2 bg-gray-50 mb-4">
                <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                  <p><strong>Account number:</strong> {{ item.accountNo }}</p>
                  <p><strong>Loan Amount:</strong> {{ item.amount }}</p>
                  <p><strong>Current Balance:</strong> {{ item.balance }}</p>
                  <p><strong>Amount Overdue:</strong> {{ item.overdue }}</p>
                  <p><strong>Instalment Amount:</strong> {{ item.instalment }}</p>
                  <p><strong>Loan Duration:</strong> {{ item.loanDuration }}</p>
                  <p><strong>Repayment Frequency:</strong> {{ item.repaymentFrequency }}</p>
                  <p><strong>Date Account Opened:</strong> {{ item.date }}</p>
                  <p><strong>Closed Date:</strong> {{ item.closedDate }}</p>
                  <p><strong>Performance Status:</strong> {{ item.performanceStatus }}</p>
                  <p><strong>Account Status:</strong> {{ item.status }}</p>
                </div>
              </td>
            </template>
          </v-data-table>
        </div>

        <div v-else class="text-sm text-gray-500 italic">No loan accounts available.</div>
      </div>

      <!-- Enquiry & Employment History -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Enquiry History -->
        <div class="bg-white rounded p-4">
          <h2 class="font-semibold text-md mb-4">Enquiry History</h2>
          <div v-if="enquiryHistory && enquiryHistory.length > 0">
            <table class="w-full text-sm text-left">
              <thead class="bg-gray-100">
                <tr>
                  <th class="p-2">Lender's Name</th>
                  <th class="p-2">Date Requested</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(enquiry, index) in enquiryHistory" :key="index" class="border-b">
                  <td class="p-2">{{ enquiry.lender }}</td>
                  <td class="p-2">{{ enquiry.date }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="text-sm text-gray-500 italic">No enquiry history available.</div>
        </div>

        <!-- Employment History -->
        <div class="bg-white rounded p-4">
          <h2 class="font-semibold text-md mb-4">Employment History</h2>
          <div v-if="employmentHistory && employmentHistory.length > 0">
            <v-data-table
              :headers="employmentHeaders"
              :items="employmentHistory"
              class="elevation-1"
              fixed-header
              height="200"
            >
              <template #item.date="{ item }">
                {{ item.date }}
              </template>
            </v-data-table>
          </div>
          <div v-else class="text-sm text-gray-500 italic">No employment history available.</div>
        </div>
      </div>

      <!-- Address History -->
      <div class="bg-white rounded p-4">
        <h2 class="font-semibold text-md mb-4">Address History</h2>
        <div v-if="addressHistory && addressHistory.length > 0">
          <div class="overflow-auto max-h-72 border rounded">
            <table class="min-w-full text-sm text-left">
              <thead class="bg-gray-100 sticky top-0 z-10">
                <tr>
                  <th class="p-3 font-medium text-gray-700">Address</th>
                  <th class="p-3 font-medium text-gray-700 w-40">Date Updated</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200">
                <tr v-for="(address, index) in addressHistory" :key="index">
                  <td class="p-3 text-gray-800">{{ address.address }}</td>
                  <td class="p-3 text-gray-800 w-40">{{ address.date }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div v-else class="text-sm text-gray-500 italic">No address history available.</div>
      </div>
    </section>

    <!-- Credit Registry Section -->
    <h1 class="text-2xl font-bold">Credit registry</h1>
    <section>
      <!-- Personal Details Summary -->
      <div v-if="idType !== 'business'" class="bg-white p-6 rounded space-y-4">
        <h2 class="text-md font-semibold mb-4">Personal details summary</h2>
        <div class="text-gray-500 text-sm italic">No personal data available.</div>
      </div>

      <div v-else>
        <!-- BUSINESS INFORMATION SECTION -->
        <div v-if="idType === 'business'" class="bg-white p-6 rounded space-y-4">
          <h2 class="text-md font-semibold">Business Information</h2>

          <div class="text-sm text-gray-500 italic">No business information available.</div>
        </div>

        <!-- DIRECTOR INFORMATION TABLE -->
        <div v-if="idType === 'business'" class="bg-white p-6 rounded space-y-4 mt-4">
          <h2 class="text-md font-semibold">Director Information</h2>

          <div class="text-sm text-gray-500 italic">No director information available.</div>
        </div>
      </div>

      <!-- Summary -->
      <div class="bg-white p-6 rounded-md mt-4">
        <h2 class="text-md font-semibold mb-6">Summary</h2>

        <!-- Show data if summary object exists and is not empty -->
        <div
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-y-6 gap-x-8 text-sm text-gray-600"
        >
          <!-- Row 1 -->
          <div>
            <p class="mb-1">Total active monthly installment</p>
            <p class="font-bold text-gray-900">{{ summary.TotalMonthlyInstalment }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of credit facilities</p>
            <p class="font-bold text-gray-900">{{ fcbcCreditAgreementSummaryCount }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of open facilities</p>
            <p class="font-bold text-gray-900">{{ summary.TotalOpenFacilities }}</p>
          </div>

          <!-- Row 2 -->
          <div>
            <p class="mb-1">Total arrear amount</p>
            <p class="font-bold text-gray-900">{{ summary.Amountarrear }}</p>
          </div>
          <div>
            <p class="mb-1">Total outstanding debts</p>
            <p class="font-bold text-gray-900">{{ summary.TotalOutstandingdebt }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of closed credit facilities</p>
            <p class="font-bold text-gray-900"></p>
          </div>

          <!-- Row 3 -->
          <div>
            <p class="mb-1">Total no of account in arrears</p>
            <p class="font-bold text-gray-900">{{ summary.TotalAccountarrear }}</p>
          </div>
          <div>
            <p class="mb-1">Total no of delinquent facilities</p>
            <p class="font-bold text-gray-900">{{ fcbcHighestDelinquencyRatingCount }}</p>
          </div>
          <div>
            <p class="mb-1">Total no written off facilities</p>
            <p class="font-bold text-gray-900">{{ summary.TotalWrittenOffFacilities }}</p>
          </div>
        </div>

        <!-- Fallback if no data -->
      </div>

      <!-- Performaing Accounts Table -->
      <div class="bg-white p-6 rounded">
        <h2 class="text-md font-semibold mb-4">Performing Accounts</h2>

        <div v-if="loanAccounts && loanAccounts.length > 0">
          <v-data-table
            :headers="loanHeaders"
            :items="loanAccounts"
            item-value="uid"
            :expanded.sync="expanded"
            show-expand
            fixed-header
            height="400"
            hide-default-footer
            class="elevation-1"
          >
            <!-- Status badge -->
            <template #item.status="{ item }">
              <v-chip
                :color="item.status === 'Closed' ? 'green' : 'red'"
                variant="tonal"
                size="small"
                class="text-white"
              >
                {{ item.status }}
              </v-chip>
            </template>

            <!-- Action button -->
            <template #item.action="{ item }">
              <v-btn size="small" color="primary" @click="toggleRow(item.uid)">
                {{ isExpanded(item.uid) ? 'Hide' : 'View' }}
              </v-btn>
            </template>

            <!-- Expanded row content -->
            <template #expanded-row="{ item }">
              <td :colspan="loanHeaders.length" class="p-4 bg-gray-50">
                <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                  <p><strong>Account number:</strong> {{ item.accountNo }}</p>
                  <p><strong>Loan Amount:</strong> {{ item.amount.toLocaleString() }}</p>
                  <p><strong>Current Balance:</strong> {{ item.balance.toLocaleString() }}</p>
                  <p><strong>Amount Overdue:</strong> {{ item.overdue?.toLocaleString() || 0 }}</p>
                  <p>
                    <strong>Instalment Amount:</strong> ₦{{
                      item.instalment?.toLocaleString() || 0
                    }}
                  </p>
                  <p><strong>Loan Duration:</strong> {{ item.duration }} months</p>
                  <p><strong>Repayment Frequency:</strong> {{ item.repaymentFrequency }}</p>
                  <p><strong>Date Account Opened:</strong> {{ item.date }}</p>
                  <p><strong>Closed Date:</strong> {{ item.closedDate }}</p>
                  <p><strong>Performance Status:</strong> {{ item.performanceStatus }}</p>
                  <p><strong>Account Status:</strong> {{ item.status }}</p>
                </div>
              </td>
            </template>
          </v-data-table>
        </div>

        <div v-else class="text-sm text-gray-500 italic">No loan accounts available.</div>
      </div>

      <!-- Delinquents Accounts -->
      <div class="bg-white p-6 rounded-md shadow">
        <h2 class="text-md font-semibold mb-4">Deliquents Accounts</h2>
        <table class="min-w-full text-left text-sm">
          <thead class="bg-gray-100">
            <tr>
              <th class="p-3 border-b">Lender's Name</th>
              <th class="p-3 border-b">Disbursement Date</th>
              <th class="p-3 border-b">Loan Amount</th>
              <th class="p-3 border-b">Loan Balance</th>
              <th class="p-3 border-b">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="delinquentAccounts.length === 0">
              <td colspan="5" class="p-4 text-center text-gray-500">
                No delinquents accounts available.
              </td>
            </tr>
            <tr
              v-for="(loan, index) in delinquentAccounts"
              :key="'delinquents-' + index"
              class="hover:bg-gray-50"
            >
              <td class="p-3 border-b">{{ loan.lender }}</td>
              <td class="p-3 border-b">{{ loan.date }}</td>
              <td class="p-3 border-b">₦{{ loan.amount.toLocaleString() }}</td>
              <td class="p-3 border-b">₦{{ loan.balance.toLocaleString() }}</td>
              <td class="p-3 border-b">
                <button class="bg-red-600 text-white text-xs px-3 py-1 rounded hover:bg-red-700">
                  View
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Closed Accounts -->
      <div class="bg-white p-6 rounded-md shadow">
        <h2 class="text-md font-semibold mb-4">Closed Accounts</h2>
        <table class="min-w-full text-left text-sm">
          <thead class="bg-gray-100">
            <tr>
              <th class="p-3 border-b">Lender's Name</th>
              <th class="p-3 border-b">Disbursement Date</th>
              <th class="p-3 border-b">Loan Amount</th>
              <th class="p-3 border-b">Loan Balance</th>
              <th class="p-3 border-b">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="closedAccounts.length === 0">
              <td colspan="5" class="p-4 text-center text-gray-500">
                No closed accounts available.
              </td>
            </tr>
            <tr
              v-for="(loan, index) in closedAccounts"
              :key="'delinquents-' + index"
              class="hover:bg-gray-50"
            >
              <td class="p-3 border-b">{{ loan.lender }}</td>
              <td class="p-3 border-b">{{ loan.date }}</td>
              <td class="p-3 border-b">₦{{ loan.amount.toLocaleString() }}</td>
              <td class="p-3 border-b">₦{{ loan.balance.toLocaleString() }}</td>
              <td class="p-3 border-b">
                <button class="bg-red-600 text-white text-xs px-3 py-1 rounded hover:bg-red-700">
                  View
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Written Off Accounts -->
      <div class="bg-white p-6 rounded mb-6">
        <h2 class="text-md font-semibold mb-4">Written Off Accounts</h2>
        <div v-if="writtenOffAccounts && writtenOffAccounts.length > 0">
          <table class="min-w-full text-left">
            <thead>
              <tr class="bg-gray-100 text-sm">
                <th class="p-2">Lender's Name</th>
                <th class="p-2">Disbursement Date</th>
                <th class="p-2">Loan Amount</th>
                <th class="p-2">Loan Balance</th>
                <th class="p-2">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, i) in writtenOffAccounts" :key="i" class="text-sm">
                <td class="p-2">{{ item.lender }}</td>
                <td class="p-2">{{ item.date }}</td>
                <td class="p-2">₦{{ item.amount.toLocaleString() }}</td>
                <td class="p-2">₦{{ item.balance.toLocaleString() }}</td>
                <td class="p-2">
                  <button
                    class="bg-blue-600 text-white text-xs px-3 py-1 rounded hover:bg-blue-700"
                  >
                    View
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="text-sm text-gray-500 italic">No written-off accounts available.</div>
      </div>

      <!-- Unknown Account Status -->
      <div class="bg-white p-6 rounded mb-6">
        <h2 class="text-md font-semibold mb-4">Unknown Accounts Status</h2>
        <div v-if="unknownAccounts && unknownAccounts.length > 0">
          <table class="min-w-full text-left">
            <thead>
              <tr class="bg-gray-100 text-sm">
                <th class="p-2">Lender's Name</th>
                <th class="p-2">Disbursement Date</th>
                <th class="p-2">Loan Amount</th>
                <th class="p-2">Loan Balance</th>
                <th class="p-2">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, i) in unknownAccounts" :key="i" class="text-sm">
                <td class="p-2">{{ item.lender }}</td>
                <td class="p-2">{{ item.date }}</td>
                <td class="p-2">₦{{ item.amount.toLocaleString() }}</td>
                <td class="p-2">₦{{ item.balance.toLocaleString() }}</td>
                <td class="p-2">
                  <button
                    class="bg-blue-600 text-white text-xs px-3 py-1 rounded hover:bg-blue-700"
                  >
                    View
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="text-sm text-gray-500 italic">No unknown accounts available.</div>
      </div>

      <!-- Inquiry History -->
      <div class="bg-white p-6 rounded mb-6">
        <h2 class="text-md font-semibold mb-4">Inquiry History</h2>
        <div v-if="inquiryHistory && inquiryHistory.length > 0">
          <table class="min-w-full text-left">
            <thead>
              <tr class="bg-gray-100 text-sm">
                <th class="p-2">Subscriber Name</th>
                <th class="p-2">Inquiry Date</th>
                <th class="p-2">Contact Phone</th>
                <th class="p-2">Inquiry Reason</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(item, i) in inquiryHistory"
                :key="i"
                class="text-sm hover:bg-gray-50 transition-colors"
              >
                <td class="p-2">{{ item.subscriber }}</td>
                <td class="p-2">{{ item.date }}</td>
                <td class="p-2">{{ item.phone }}</td>
                <td class="p-2">{{ item.reason }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="text-sm text-gray-500 italic">No inquiries available.</div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, defineExpose } from 'vue'
import { ElNotification, ElMessage } from 'element-plus'
import html2pdf from 'html2pdf.js'

const props = defineProps({
  fcbcCreditAgreementSummaryCount: Number,
  fcbcHighestDelinquencyRatingCount: Number,
  idType: String,
  businessData: Object,
  directors: Array,
  personal: Object,
  summary: Object,
  creditAgreementSummary: Array,
  enquiryHistory: Array,
  employmentHistory: Array,
  addressHistory: Array,

  loanAccounts: Array,
  delinquentAccounts: Array,
  closedAccounts: Array,
  derogatoryAccounts: Array,
  writtenOffAccounts: Array,
  unknownAccounts: Array,
  inquiryHistory: Array
})
const expanded = ref([])

const toggleRow = (uid) => {
  expanded.value = expanded.value.includes(uid) ? [] : [uid]
}

const isExpanded = (uid) => expanded.value.includes(uid)

const loanHeaders = [
  { title: "Lender's Name", key: 'lender' },
  { title: 'Disbursement Date', key: 'date' },
  { title: 'Loan Amount', value: 'amount' },
  { title: 'Loan Balance', key: 'balance' },
  { title: 'Status', key: 'status' },
  { title: 'Action', key: 'action', sortable: false }
]

const employmentHeaders = [
  { title: 'Employer Name', key: 'employerName' },
  { title: 'Date Updated', key: 'date' }
]


function getStatusColor(status) {
  if (!status || status.trim() === '') return 'grey'

  const normalized = status.toLowerCase().trim()

  if (normalized === 'closed') return 'green'
  if (normalized === 'open') return 'red'
  if (normalized === 'paid up') return 'blue'

  return 'grey' // fallback for unknown values
}

const pdfContent = ref(null)

const exportPDF = () => {
  const now = new Date()
  const dateString = now.toISOString().slice(0, 16).replace('T', '_').replace(':', '-')

  let filename = ''

  if (props.idType === 'business' && props.businessData) {
    const businessName = props.businessData.BusinessName || 'Business'
    filename = `${businessName}_${dateString}.pdf`
  } else {
    const firstName = props.personal?.FirstName || 'FirstName'
    const lastName = props.personal?.Surname || 'LastName'
    filename = `${firstName}_${lastName}_${dateString}.pdf`
  }

  // ✅ Show loading message
  const loadingMessage = ElMessage({
    message: 'Downloading report...',
    type: 'info',
    duration: 0, // stays until closed
    showClose: false
  })

  setTimeout(() => {
    html2pdf()
      .set({
        margin: 0.5,
        filename,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2 },
        jsPDF: { unit: 'in', format: 'letter', orientation: 'portrait' }
      })
      .from(pdfContent.value)
      .save()
      .then(() => {
        // ✅ Close loading message
        loadingMessage.close()

        // ✅ Show success notification
        ElNotification({
          title: 'Download Complete',
          message: 'Report has been downloaded successfully!',
          type: 'success',
          duration: 3000
        })
      })
  }, 500)
}

// 👇 Expose to parent
defineExpose({ exportPDF })
</script>
