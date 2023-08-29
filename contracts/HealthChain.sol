// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.9.0;

contract HealthChain{

    //enums
    // {A = 0, AN = 1, B = 2, BN = 3, AB = 4, ABN = 5, O = 6, ON = 7}
    enum BloodType {A, AN, B, BN, AB, ABN, O, ON}
    // {M = 0, F = 1}
    enum Gender {M, F}

    // medical reports from a medical appointment
    struct MedicalReport{
        uint patient;
        uint doctor;
        string[] symptoms;
        string diagnostic;
        string prescription;
        string annotation;
    }

    // doctor information
    struct Doctor{
        uint id;
        address owner;
        string name;
        string crm;
        string area;
        string expertise;
    }

    // patient information
    struct Patient{
        address owner;
        uint id;
        uint birthday;
        uint birth_month;
        uint birth_year;
        string country;
        string state;
        string city;
        string[] important_notes;
        string[] known_diseases;
        string[] known_allergies;
        BloodType blood_type;
        Gender gender;
    }

    // mapping to link one patient address to one medical record
    mapping(address => uint) private my_patient_record;
    // mapping to link one address to one doctor
    mapping(address => uint) private my_doctor_record;
    // mapping to link a patient ID to your medical reports
    mapping(uint => MedicalReport[]) private my_medical_reports;
    // mapping to link a patient ID to your authorized doctors
    mapping(uint => uint[]) private authorized_doctors;
    // mapping to link a patient ID to your trusted accounts
    mapping(uint => uint[]) private trusted_accounts;

    Patient[] private patient_records;
    Doctor[] private doctor_records;

    // check if exists doctor
    modifier exists_doctor(uint _doctor_id){
        require(
            bytes(doctor_records[_doctor_id].crm).length != 0,
             "Doctor not found"
        );
        _;
    }

    // check if exists patient
    modifier exists_patient(uint _patient_id){
        require(
            bytes(patient_records[_patient_id].country).length != 0,
             "Patient not found"
        );
        _;
    }

    // check if the sender is an trusted account to passed account
    modifier only_trusted(uint _patient_id){
        require(
            exists(my_patient_record[msg.sender], trusted_accounts[_patient_id]), 
            "This account is not trusted to this patient"
        );
        _;
    }

    // check if the doctor is already authorized to passed account
    modifier doctor_not_authorized(uint _patient_id, uint _doctor_id){
        require(
            !exists(_doctor_id, authorized_doctors[_patient_id]), 
            "This doctor is already authorized to this patient"
        );
        _;
    }

    // check if the doctor is not already authorized to passed account
    modifier doctor_authorized(uint _patient_id, uint _doctor_id){
        require(
            exists(_doctor_id, authorized_doctors[_patient_id]), 
            "This doctor is not already authorized to this patient"
        );
        _;
    }

    // check if the account is already authorized to passed patient
    modifier account_not_trusted(uint _patient_id, uint _account_id){
        require(
            !exists(_account_id, trusted_accounts[_patient_id]), 
            "This account is already trusted to this patient"
        );
        _;
    }

    // check if the account is not already trusted to passed patient
    modifier account_trusted(uint _patient_id, uint _account_id){
        require(
            exists(_account_id, trusted_accounts[_patient_id]), 
            "This account is not already trusted to this patient"
        );
        _;
    }

    // check if exists a uint value on a uint list
    function exists(uint value, uint[] memory list) private pure returns(bool){
        for(uint i = 0; i < list.length; i++){
            if(value == list[i]){
                return true;
            }
        }
        return false;
    }

    // remove item from a authorized or trust list
    function remove_item(uint value, uint id, uint list_type) private{
        uint[] memory list;
        // list_type == 0 is to modify authorized_doctors
        if(list_type == 0){
            list = authorized_doctors[id];
        }
        // list_type == 1 is to modify trusted_accounts
        else{
            list = trusted_accounts[id];
        }

        uint index = 0;
        bool finded = false;
        for(uint i = 0; i < list.length; i++){
            if(value == list[i]){
                index = i;
                finded = true;
            }
        }

        if(finded){
            // list_type == 0 is to modify authorized_doctors
            if(list_type == 0){
                // shift elements after the index
                for(uint i = index; i < authorized_doctors[id].length - 1; i++){
                    authorized_doctors[id][i] = authorized_doctors[id][i + 1];
                }
                // remove the last position
                authorized_doctors[id].pop();
            }
            // list_type == 1 is to modify trusted_accounts
            else{
                // shift elements after the index
                for(uint i = index; i < trusted_accounts[id].length - 1; i++){
                    trusted_accounts[id][i] = trusted_accounts[id][i + 1];
                }
                // remove the last position
                trusted_accounts[id].pop();
            }
        }
    }

    // create medical records to one patient
    function create_medical_record(
        uint _birthday, 
        uint _birth_month, 
        uint _birth_year,
        string memory _country,
        string memory _state,
        string memory _city,
        string[] memory _important_notes,
        string[] memory _known_diseases,
        string[] memory _known_allergies,
        uint _blood_type,
        uint _gender
    ) public returns (uint id){
        require((_birthday >= 1 && _birthday <= 31), "invalid birthday");
        require((_birth_month >= 1 && _birth_month <= 12), "invalid birth month");
        require((_blood_type >= 0 && _blood_type <= 7), "blood type must be between 0 and 7");
        require((_gender == 0 || _gender == 1), "gender must be between 0 and 1");

        id = patient_records.length;
        Patient memory patient = Patient({
            owner: msg.sender,
            id: id,
            birthday: _birthday,
            birth_month: _birth_month,
            birth_year: _birth_year,
            country: _country,
            state: _state,
            city: _city,
            important_notes: _important_notes,
            known_diseases: _known_diseases,
            known_allergies: _known_allergies,
            blood_type: BloodType(_blood_type),
            gender: Gender(_gender)
        });

        // store the patient's medical record in the patient list
        patient_records.push(patient);

        // linking account to your medical record
        my_patient_record[msg.sender] = id;
    }

    // create doctor record
    function create_doctor_record(
        string memory _name,
        string memory _crm,
        string memory _area,
        string memory _expertise
    ) public returns (uint id){
        
        id = doctor_records.length;
        Doctor memory doctor = Doctor({
            owner: msg.sender,
            id: id,
            name: _name,
            crm: _crm,
            area: _area,
            expertise: _expertise
        });

        // store the doctor information in the doctor list
        doctor_records.push(doctor);

        // link account to your register
        my_doctor_record[msg.sender] = id;
    }

    // create medical report
    function create_medical_report(
        uint _patient_id,
        string[] memory _symptoms,
        string memory _diagnostic,
        string memory _prescription,
        string memory _annotation
    ) public doctor_authorized(_patient_id, my_doctor_record[msg.sender])
        exists_doctor(my_doctor_record[msg.sender])
        exists_patient(_patient_id)
        returns (MedicalReport memory){
        MedicalReport memory report = MedicalReport({
            patient: _patient_id,
            doctor: my_doctor_record[msg.sender],
            symptoms: _symptoms,
            diagnostic: _diagnostic,
            prescription: _prescription,
            annotation: _annotation
        });

        // link patient to created report
        my_medical_reports[_patient_id].push(report);

        return report;
    }

    // get a medical record by sender address
    function get_my_medical_record(string memory verify) public view returns(Patient memory){
       uint id = my_patient_record[msg.sender];
        return patient_records[id];
    }

    // get a medical record by Patient Id
    function get_medical_record_by_id(uint id) public view returns(Patient memory){
        return patient_records[id];
    }

    // get sender medical reports
    function get_medical_reports(string memory verify) public view returns(MedicalReport[] memory){
        uint id = my_patient_record[msg.sender];
        return my_medical_reports[id];
    }

    // get a doctor record by sender address
    function get_my_doctor_profile(string memory verify) public view returns(Doctor memory){
       uint id = my_doctor_record[msg.sender];
        return doctor_records[id];
    }

    // get a medical record by Doctor Id
    function get_doctor_record_by_id(uint id) public view returns(Doctor memory){
        return doctor_records[id];
    }

    // get my authorized doctors
    function get_my_authorized_doctors(string memory verify) public view returns(uint[] memory){
        uint patient_id = my_patient_record[msg.sender];
        return authorized_doctors[patient_id];
    }

    // get my trusted account list
    function get_my_trusted_accounts(string memory verify) public view returns(uint[] memory){
        uint patient_id = my_patient_record[msg.sender];
        return trusted_accounts[patient_id];
    }

    // the patient can add trusted doctor in your authorized doctor list and
    function give_doctor_permission(uint _doctor_id) public
        exists_doctor(_doctor_id)
        doctor_not_authorized(my_patient_record[msg.sender], _doctor_id){
        
        authorized_doctors[my_patient_record[msg.sender]].push(_doctor_id);
    }

    // trusted accounts can add trusted doctors in another authorized doctor list account
    function give_doctor_permission(uint _account_id, uint _doctor_id) public
         exists_doctor(_doctor_id)
         only_trusted(_account_id)
         doctor_not_authorized(_account_id, _doctor_id){
        
        authorized_doctors[_account_id].push(_doctor_id);
    }

    // the patient can remove doctors from your authorized doctor list
    function remove_doctor_permission(uint _doctor_id) public 
        exists_doctor(_doctor_id)
        doctor_authorized(my_patient_record[msg.sender], _doctor_id){
            uint patient_id = my_patient_record[msg.sender];
            remove_item(_doctor_id, patient_id, 0);    
    }

    // trusted accounts can remove doctors from another authorized doctor list account
    function remove_doctor_permission(uint _account_id, uint _doctor_id) public
        exists_doctor(_doctor_id)
        only_trusted(_account_id)
        doctor_authorized(_account_id, _doctor_id){
            uint patient_id = my_patient_record[msg.sender];
            remove_item(_doctor_id, patient_id, 0);
    }

    // the patient can add trusted accounts in your trusted list
    function add_trusted_account(uint _account_id) public 
        exists_patient(_account_id)
        account_not_trusted(my_patient_record[msg.sender], _account_id){
            trusted_accounts[my_patient_record[msg.sender]].push(_account_id);     
    }

    // the patient can remove trusted accounts from your trusted list
    function remove_trusted_account(uint _account_id) public 
        exists_patient(_account_id)
        account_trusted(my_patient_record[msg.sender], _account_id){
            remove_item(_account_id, my_patient_record[msg.sender], 1);
    }
}