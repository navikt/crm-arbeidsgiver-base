/**
 * Created by u157416 on 11/10/2019.
 */

({

  doInit: function (component, event, helper) {
    helper.getExternalMessages(component);
  },

  onRender : function(component,event,helper){
    helper.updateScroll(component);
  },

  enableButton: function(component, event, helper){
    let newMessage = component.get("v.newMessage");
    if(newMessage !== ""){
      component.set('v.disable', false);
    } else {
      component.set('v.disable', true);
    }
  },

  createMessages: function (component, event, helper) {
    let recordId = component.get("v.recordId");
    let action = component.get("c.createMessage");
    let newMessage = component.get("v.newMessage");
    action.setParams({
      'recordId' : recordId,
      'newMessage' : newMessage
    });

    action.setCallback(this, function(result) {
      if(component.isValid() && result.getState() === 'SUCCESS') {
        let messageResult = result.getReturnValue();
        component.set('v.newMessage', newMessage);
        component.find("messageText").set("v.value", "");
        component.set('v.disable', true);
        helper.getExternalMessages(component);
      }
      else {
        console.log(result.getError());
      }
    });
    $A.enqueueAction(action);
  }

})