/**
 * Created by u157416 on 11/10/2019.
 */

({
  getExternalMessages: function (component, event, helper) {
    let action = component.get("c.getMessages");
    let recordId = component.get("v.recordId");
    action.setParams({
      'recordId' : recordId
    });

    action.setCallback(this, function(result) {
      if(component.isValid() && result.getState() === 'SUCCESS') {
        let messages = result.getReturnValue();

        component.set('v.messages', messages);
        console.log('messages', messages);

        for (let i = 0; i < messages.length; i++) {
          let date = new Date(messages[i].CreatedDate);
          let year = date.getFullYear();
          let month = (1 + date.getMonth()).toString();
          month = month.length > 1 ? month : '0' + month;
          let day = date.getDate().toString();
          day = day.length > 1 ? day : '0' + day;
          console.log('messages[i].CreatedDate', messages[i].CreatedDate);
          let time = new Date(messages[i].CreatedDate).toString().substring(16,21);
          messages[i].CreatedDateString__c = day + '.' + month + '.' + year + ' ' + time;
        }

      }
      else {
        console.log(result.getError());
      }
    });
    $A.enqueueAction(action);
  },
  updateScroll : function(component, event, helper){
    let scroller = component.find("scroller");
    scroller.scrollTo("bottom");
  }
})