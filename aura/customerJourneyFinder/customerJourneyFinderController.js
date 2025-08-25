({
    handleSearchChange : function(component, event, helper) {
        // Ambil nilai setiap kali berubah, tapi tunggu sebentar sebelum mencari
        const keyword = component.get("v.searchKeyword");
        if (keyword.length > 2) {
             helper.searchAccountsHelper(component, keyword);
        } else {
            component.set("v.accountList", []);
        }
    },

    handleAccountSelect : function(component, event, helper) {
        // Ambil ID dari akun yang diklik
        const selectedAccountId = event.currentTarget.dataset.recordid;
        helper.getJourneyDataHelper(component, selectedAccountId);
    },

    resetComponent : function(component, event, helper) {
        // Bersihkan semua atribut untuk kembali ke tampilan pencarian
        component.set("v.searchKeyword", "");
        component.set("v.accountList", []);
        component.set("v.journeyData", null);
        component.set("v.opportunityData", null); // Jangan lupa reset atribut tabel
    }
})