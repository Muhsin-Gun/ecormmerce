
const axios = require('axios');

// Using the standard firebase emulator port
const FUNCTION_URL = 'http://127.0.0.1:5001/eshop-be005/us-central1/mpesaStkPush';

// Test Data
const payload = {
    data: {
        phoneNumber: '254793027220', // User's number
        amount: 1,
        accountReference: 'TEST_REF_FUNC',
        transactionDesc: 'Function Test',
    }
};

async function testFunction() {
    console.log('Testing Cloud Function Endpoint:', FUNCTION_URL);

    try {
        const response = await axios.post(FUNCTION_URL, payload);
        console.log('Function Response:', JSON.stringify(response.data, null, 2));

        if (response.data.result && response.data.result.success) {
            console.log('✅ Cloud Function Test Passed!');
        } else {
            // Check for wrapped result often returned by callable functions
            if (response.data.result && response.data.result.responseDescription) {
                console.log('✅ Cloud Function Test Passed (Raw Response)!');
            } else {
                console.log('⚠️ Unexpected Response Structure');
            }
        }
    } catch (error) {
        if (error.response) {
            console.error('❌ Function Error:', error.response.status, error.response.data);
        } else {
            console.error('❌ Connection Error:', error.message);
            console.error('   (Ensure firebase emulators are running)');
        }
    }
}

testFunction();
