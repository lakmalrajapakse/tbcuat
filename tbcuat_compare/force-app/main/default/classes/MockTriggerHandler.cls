/**
 * @description a mock trigger handler
 */
public with sharing class MockTriggerHandler extends TriggerHandler {

	//Used when testing mock to ensure correct methods are called.
	public String triggerContextCalled;
	
	public MockTriggerHandler(){
		//optionally set max recursion default is null (no max recursion defined).
		//this.setMaxRecursion(2);
	}

	/**
	* @description implementation for the before insert trigger context method.
	**/
	public override void beforeInsert() {
		super.beforeInsert(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'beforeInsert';
	}

	/**
	* @description implementation for the before update trigger context method.
	**/
	public override void beforeUpdate() {
		super.beforeUpdate(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'beforeUpdate';
	}

	/**
	* @description implementation for the before delete trigger context method.
	**/
	public override void beforeDelete() {
		super.beforeDelete(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'beforeDelete';
	}

	/**
	* @description implementation for the after insert trigger context method.
	**/
	public override void afterInsert() {
		super.afterInsert(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'afterInsert';
	}

	/**
	* @description implementation for the after update trigger context method.
	**/
	public override void afterUpdate() {
		super.afterUpdate(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'afterUpdate';
	}

	/**
	* @description implementation for the after delete trigger context method.
	**/
	public override void afterDelete() {
		super.afterDelete(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'afterDelete';
	}

	/**
	* @description implementation for the after undelete trigger context method.
	**/
	public override void afterUndelete() {
		super.afterUndelete(); //Not needed but calls TriggerHandler defaults.
		this.triggerContextCalled = 'afterUndelete';
	}

}