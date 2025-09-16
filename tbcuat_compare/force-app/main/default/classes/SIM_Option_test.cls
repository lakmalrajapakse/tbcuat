@isTest
private with sharing class SIM_Option_test {
    @isTest
    static void constructors() {
        String value = 'testValue';
        String label = 'testLabel';
        Boolean disabled = true;
        String alternativeText = 'testAlternativeText';
        String iconName = 'testIconName';

        SIM_Option option = new SIM_Option(value, label, disabled, alternativeText, iconName);
        System.assertEquals(value, option.value);
        System.assertEquals(label, option.label);
        System.assertEquals(disabled, option.disabled);
        System.assertEquals(alternativeText, option.alternativeText);
        System.assertEquals(iconName, option.iconName);

        option = new SIM_Option(value, label, disabled, alternativeText);
        System.assertEquals(value, option.value);
        System.assertEquals(label, option.label);
        System.assertEquals(disabled, option.disabled);
        System.assertEquals(alternativeText, option.alternativeText);
        System.assertEquals(null, option.iconName);

        option = new SIM_Option(value, label);
        System.assertEquals(value, option.value);
        System.assertEquals(label, option.label);
        System.assertEquals(false, option.disabled);
        System.assertEquals(null, option.alternativeText);
        System.assertEquals(null, option.iconName);

        option = new SIM_Option(value, label, disabled);
        System.assertEquals(value, option.value);
        System.assertEquals(label, option.label);
        System.assertEquals(true, option.disabled);
        System.assertEquals(null, option.alternativeText);
        System.assertEquals(null, option.iconName);
    }
}