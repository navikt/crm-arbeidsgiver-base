({
    init : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                "title": "Til informasjon!",
                "message": "Det er ikke mulig å opprette møte via denne knappen",
                "type": "info"
            });
            toastEvent.fire();
        }
    }
})