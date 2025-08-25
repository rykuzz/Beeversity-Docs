({
    searchAccountsHelper : function(component, keyword) {
        // Panggil metode Apex untuk mencari
        let action = component.get("c.searchAccounts");
        action.setParams({
            "keyword": keyword
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.accountList", response.getReturnValue());
            } else if (state === "ERROR") {
                let errors = response.getError();
                console.error("Error saat mencari akun: ", errors);
            }
        });

        $A.enqueueAction(action);
    },

    getJourneyDataHelper : function(component, accountId) {
        component.set("v.isLoading", true);
        // Kosongkan daftar pencarian agar tidak mengganggu UI
        component.set("v.accountList", []);

        // Panggil metode Apex untuk mengambil data 360
        let action = component.get("c.getJourneyData");
        action.setParams({
            "accountId": accountId
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            let state = response.getState();
            if (state === "SUCCESS") {
                let journeyResult = response.getReturnValue();
                
                // Set data utama
                component.set("v.journeyData", journeyResult);
                
                // Set data tabel secara terpisah
                component.set("v.opportunityData", journeyResult.opps); 

            } else if (state === "ERROR") {
                let errors = response.getError();
                console.error("Error saat mengambil data perjalanan: ", errors);
                // Set pesan error untuk ditampilkan ke pengguna jika perlu
                component.set("v.error", "Gagal memuat data pelanggan.");
            }
        });

        $A.enqueueAction(action);
    }
})