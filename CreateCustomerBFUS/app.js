lbs.apploader.register('CreateCustomerBFUS', function () {
    var self = this;

    /*Config (version 2.0)
        This is the setup of your app. Specify which data and resources that should loaded to set the enviroment of your app.
        App specific setup for your app to the config section here, i.e self.config.yourPropertiy:'foo'
        The variabels specified in "config:{}", when you initalize your app are available in in the object "appConfig".
    */
    self.config =  function(appConfig) {
            this.dataSources = [
                {type: 'activeInspector', source: '', alias: 'rec'}
            ];
            this.resources = {
                //scripts: [], // <= External libs for your apps. Must be a file
                scripts: ['script/app.customer.js'], // <= External libs for your apps. Must be a file
                styles: ['app.css'], // <= Load styling for the app.
                libs: [] // <= Already included libs, but not loaded per default. Example json2xml.js
            };

            this.baseURI = appConfig.baseURI;
            this.ewiKey = appConfig.ewiKey;
            this.eligibleForBFUSSending = appConfig.eligibleForBFUSSending;
            this.crossDomainCall = appConfig.crossDomainCall;
            this.fieldMappings = appConfig.fieldMappings;
    };

    /*Initialize
        Initialize happens after the data and recources are loaded but before the view is rendered.
        Here it is your job to implement the logic of your app, by attaching data and functions to 'viewModel' and then returning it
        The data you requested along with localization are delivered in the variable viewModel.
        You may make any modifications you please to it or replace is with a entirely new one before returning it.
        The returned viewModel will be used to build your app.
        
        Node is a reference to the HTML-node where the app is being initalized form. Frankly we do not know when you'll ever need it,
        but, well, here you have it.
    */
    self.initialize = function (node, viewModel) {
        self.Customer = new Customer();
        self.resourceURI = '';
        self.suppressPinCodeWarning = false;
        self.suppressAddressWarning = false;
        self.lastWarning = '';

        self.BFUSWarnings = {};
        self.BFUSWarnings.warningPinCode = 'Error.Customer.CustomerWithPinCodeAlreadyExists';
        self.BFUSWarnings.warningCompanyCode = 'Error.Customer.CustomerWithCompanyCodeAlreadyExists';
        self.BFUSWarnings.warningAddress = 'Error.Customer.##TODO';

        viewModel.warningText = ko.observable('');
        viewModel.UIErrorText = ko.observable('');
        viewModel.isAlreadyInBFUS = ko.observable(self.Customer.isIntegratedWithBFUS(self.config.fieldMappings.CustomerId));
        
        viewModel.isRecordSaved = ko.computed(function() {
            alert('hej');
            return self.Customer.isRecordSaved()
        }, this);

        viewModel.isEligibleForSendingToBFUS = ko.computed(function() {
            return self.Customer.eligibleForBFUSSending(self.config.eligibleForBFUSSending)
        }, this);

        //Enable cross domain calls if needed.
        $.support.cors = self.config.crossDomainCall;

        function toggleLoader(showLoader) {
            toggleInfo(false);
            toggleError(false);
            if (showLoader) {
                $('div#loading').slideDown();
            }
            else {
                $('div#loading').slideUp();
            }
        }

        function toggleInfo(showInfo) {
            if (showInfo) {
                $('div#info').slideDown();
            }
            else {
                $('div#info').slideUp();
            }
        }

        function toggleWarning(showWarning) {
            if (showWarning) {
                $('div#warning').slideDown();
            }
            else {
                $('div#warning').slideUp();
            }
            $('button#createupdatebutton').prop('disabled', showWarning);
        }

        function toggleError(showError) {
            if (showError) {
                $('div#error').slideDown();
            }
            else {
                $('div#error').slideUp();
            }
        }

        /**
            Called when clicking on the create/update button.
        */
        viewModel.createOrUpdate = function() {
            
            if (!viewModel.isRecordSaved()) {
                treatError('', viewModel.localize.app_CreateCustomerBFUS.e_recordNotSaved);
                return;
            }
            toggleLoader(true);
            if (viewModel.isAlreadyInBFUS()) {
                self.resourceURI = 'Common/Customer/UpdateCustomer_v1';
                viewModel.customerData = new self.Customer.updateCustomerJSON();   //##TODO: Implementera updateCustomer.
            }
            else {
                self.resourceURI = 'Common/Customer/CreateCustomer_v1';
                viewModel.customerData = new self.Customer.createCustomerJSON(self.config.fieldMappings, viewModel.rec, self.suppressPinCodeWarning, self.suppressAddressWarning);
            }
            window.setTimeout(function() {sendToBFUS()}, 500);
        }

        sendToBFUS = function() {
            var json = 
                      "{" +
                        "Header: {" +
                          "'ExternalId':'FER_TESTAR'," +
                          "'SuppressPinCodeWarning':false," +
                          "'SuppressAdressWarning':true " +
                        "}," +
                        "Customer: {" +
                          "'IsProtectedIdentity':false," +
                          "'FirstName':'Kalle'," +
                          "'LastName':'Anka'," +
                          "'IsBusinessCustomer':false," +     // IsBusinessCustomer = false => PinCode (personal-code) must be set .
                          "'PinCode':'19-760619-4657'," +     // PinCode (Personal-code)
                          "'CompanyCode':null," +             // IsBusinessCustomer = true => CompanyCode must be set.
                          "EmailInformation: {" +
                            "'AcceptEMail':true," +
                            "'EMail1':'test@hotmail.com'," +
                            "'EMail2':'test2@hotmail.com'," +
                            "'EMail3':'test3@hotmail.com'" +
                          "},"+
                          "SMSInformation: {" +
                              "'AcceptSMS':false" +
                          "}," +
                          "Phones: [{" +
                            "'PhoneTypeId':'10980200'," +
                            "'Number':'070-5566778'" +
                          "}]," +
                          "Addresses:[{" +
                            "'AddressTypeId':'10090000',"+    // At least one postal adress!
                            "'StreetName':'Roskildevej',"+      
                            "'StreetQualifier':'38',"+       
                            "'StreetNumberSuffix':'C',"+    
                            "'PostOfficeCode':'2000',"+
                            "'City':'Frederiksberg',"+
                            "'CountryCode':'DK',"+            // If null => default will be 'SE' 
                            "'ApartmentNumber':'2',"+
                            "'FloorNumber':'3'" +
                          "}],"+
                        "}," +
                      "}";
            
            $.ajax({
                type: "POST",
                url: self.config.baseURI + self.resourceURI,
                data: json,     //JSON.stringify(viewModel.customerData),
                contentType: "application/json",
                headers: {
                    'Authorization' : 'Basic ' + self.config.ewiKey,
                    'Accept-Language' : 'sv-SE'
                },
                success: function(data) {
                    // Check if warning for existing pin code
                    if (data !== undefined) {
                        if (data.Header !== undefined) {
                            if (data.Header.ErrorInformation !== null) {
                                var errorCode = data.Header.ErrorInformation.ErrorCode;
                                var msg = errorCode + '.   Complete JSON: ' + JSON.stringify(data);

                                // Take care of warnings.
                                if (errorCode === self.BFUSWarnings.warningPinCode
                                        || errorCode === self.BFUSWarnings.warningCompanyCode
                                        || errorCode === self.BFUSWarnings.warningAddress) {
                                    treatWarning(msg, errorCode);
                                }
                                // Not a warning but an actual error.
                                else {
                                    treatError(msg, viewModel.localize.app_CreateCustomerBFUS.e_couldNotSend);
                                }
                            }
                            else    //Customer created or updated in BFUS
                            {
                                treatSuccess(data.Content.CustomerId, data.Content.CustomerCode);
                            }
                        }
                    }
                },
                error: function(errMsg) {
                    treatError(JSON.stringify(errMsg), viewModel.localize.app_CreateCustomerBFUS.e_couldNotSend);
                }
            });
        }

        /**
            Called when clicking on the yes button that appears when a warning was returned from BFUS.
        */
        viewModel.warningYes = function() {
            
            if (self.lastWarning === self.BFUSWarnings.warningPinCode || self.lastWarning === self.BFUSWarnings.warningCompanyCode) {
                self.suppressPinCodeWarning = true;
            }
            else if (self.lastWarning === self.BFUSWarnings.warningAddress) {
                self.suppressAddressWarning = true;
            }
            toggleWarning(false);
            viewModel.createOrUpdate();
        }

        /**
            Called when clicking on the no button that appears when a warning was returned from BFUS.
        */
        viewModel.warningNo = function() {
            toggleWarning(false);
        }

        treatSuccess = function(customerId, customerCode) {
            toggleLoader(false);
            toggleInfo(true);
            viewModel.isAlreadyInBFUS(true);
            lbs.common.executeVba('app_CreateCustomerBFUS.saveBFUSResponseData,' 
                                    + lbs.activeInspector.ID + ',' 
                                    + self.config.fieldMappings.CustomerId + ',' 
                                    + customerId + ',' 
                                    + self.config.fieldMappings.CustomerCode + ',' 
                                    + CustomerCode);
            window.setTimeout(function() {
                    toggleInfo(false);
                }, 3000);
        }

        treatWarning = function(logMsg, errorCode) {
            lbs.log.logToInfolog('warning', logMsg);
            self.lastWarning = errorCode;

            if (errorCode === self.BFUSWarnings.warningPinCode) {
                viewModel.warningText(viewModel.localize.app_CreateCustomerBFUS.warningTextPinCode);
            }
            else if (errorCode === self.BFUSWarnings.warningCompanyCode) {
                viewModel.warningText(viewModel.localize.app_CreateCustomerBFUS.warningTextCompanyCode);
            }
            else if (errorCode === self.BFUSWarnings.warningAddress) {
                if (viewModel.isAlreadyInBFUS()) {
                    viewModel.warningText(viewModel.localize.app_CreateCustomerBFUS.warningTextAddressUpdate);
                }
                else {
                    viewModel.warningText(viewModel.localize.app_CreateCustomerBFUS.warningTextAddressCreate);
                }
            }
            toggleLoader(false);
            toggleWarning(true);
        }

        treatError = function(logMsg, UIMsg) {
            if (logMsg !== '') {
                lbs.log.logToInfolog('error', logMsg);
            }
            viewModel.UIErrorText(UIMsg);
            toggleLoader(false);
            toggleError(true);
            window.setTimeout(function() {
                    toggleError(false);
                }, 3000);
        }


        //Success-svar:
        // {"Header":{"ErrorInformation":null,"ObjectVersion":2,"Success":true,"PerformanceTime":"00:00:08.8608000","InParameters":null},"Content":{"CustomerId":1033974840,"CustomerCode":"281"}}
        //Kund-id är den ”interna identifikationen för kund medan kundnummret är den ”synliga” nummerkoden

        return viewModel;
    };
});