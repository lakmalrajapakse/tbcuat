import { LightningElement, wire, track } from 'lwc';
import getPayrollCycles from '@salesforce/apex/SIM_LookupSearchController.getPayrollCycles';

export default class PayrollCycleSelector extends LightningElement {
    @track payrollCycles = []; 
    selectedPayrollCycle;
    weekStart;
    weekEnd;
    @wire(getPayrollCycles)
    wiredPayrollCycles({ error, data }) {
        if (data) {
    
            // Create an array with "None" as the first element
            this.payrollCycles = [
                {
                    label: 'None',
                    value: 'None',  // Assuming value should be 'None' for the placeholder
                    startDate: null,  // Set to null or any appropriate placeholder
                    endDate: null,      // Set to null or any appropriate placeholder
                    locked: 'false'
                },
                ...data.map(item => ({
                    label: `${item.startDate} - ${item.endDate}`,  // Correct format
                    value: item.value,
                    startDate: item.startDate,
                    endDate: item.endDate,
                    locked: item.locked
                }))
            ];
    
            console.log('✅ Formatted Payroll Cycles:', JSON.stringify(this.payrollCycles));
        } else if (error) {
            console.error('❌ Error fetching payroll cycles:', JSON.stringify(error));
        }
    }
    
    handlePayrollCycle(event) {
        this.selectedPayrollCycle = event.detail.value;
        console.log('🎯 Selected Payroll Cycle:', this.selectedPayrollCycle);

        const selectedCycle = this.payrollCycles.find(item => item.value === this.selectedPayrollCycle);

        if (selectedCycle && this.selectedPayrollCycle != 'None') {
            this.weekStart = this.convertFormat(selectedCycle.startDate);
            this.weekEnd = this.convertFormat(selectedCycle.endDate);
            this.locked = selectedCycle.locked;
        }
        else
        {
            this.weekStart= null;
            this.weekEnd = null; 
            this.locked = 'false';
        }
        console.log('📅 Week Start:', this.weekStart);
        console.log('📅 Week End:', this.weekEnd);

            // Dispatch custom event to notify parent of the new dates
            const dateChangeEvent = new CustomEvent('cyclechange', {
            detail: {
                cycle: this.selectedPayrollCycle != 'None' ? this.selectedPayrollCycle : null,
                startDate: this.weekStart,
                endDate: this.weekEnd,
                locked: this.locked
            }
        });

        // Dispatch the event to the parent
        this.dispatchEvent(dateChangeEvent);
    }

    convertFormat(dateString) {
        let date = dateString.split('/');
        // mm/dd/yyyy
        return `${date[1]}/${date[0]}/${date[2]}`;
    }

}