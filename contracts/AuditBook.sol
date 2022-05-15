// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AuditBook {
    enum StateType { Pending, Approved, Rejected }
    enum AuditState { Submitted, Approved, Rejected }
    enum CompanyType { Audit, Auditable }

    struct Company {
        address account;
        string name;
        StateType state;
        string changeStateMessage;
        uint[] auditReference; //Index reference to Audit array (see below)
    }

    struct Audit {
        uint id;
        address auditCompanies;
        address auditableCompanies;
        AuditState state;
        string finding;
    }

    address public admin;
    string public adminName;

    address[] auditCompaniesAddresses;
    address[] auditableCompaniesAddresses;
    mapping(address => Company) public auditCompanies;
    mapping(address => Company) public auditableCompanies;

    uint auditsCounter;
    Audit[] audits;

    event AuditCompanyStateChanged(string companyName, StateType actualState);
    event AuditableCompanyStateChanged(string companyName, StateType actualState);
    event AuditSubmitted(Audit audit);
    event AuditSubmittedStateChanged(Audit audit);

    constructor() {
        admin = msg.sender;
        auditsCounter = 0;
    }

    /* Administrator */

    function setAdminName(string memory _name) external {
        require(
            msg.sender == admin,
            "You must be the administrator to set the name"
        );
        adminName = _name;
    }

    function getAuditCompanies() external view returns (Company[] memory) {
        uint length = auditCompaniesAddresses.length;
        Company[] memory companies = new Company[](length);

        for (uint i = 0; i < length; i++) {
            companies[i] = auditCompanies[auditCompaniesAddresses[i]];
        }

        return companies;
    }

    function getAuditableCompanies() external view returns (Company[] memory) {
        uint length = auditableCompaniesAddresses.length;
        Company[] memory companies = new Company[](length);

        for (uint i = 0; i < length; i++) {
            companies[i] = auditableCompanies[auditableCompaniesAddresses[i]];
        }

        return companies;
    }

    function getApprovedAuditableCompanies() external view returns (Company[] memory) {
        uint length = auditableCompaniesAddresses.length;
        uint countApproved = 0;

        for (uint i = 0; i < length; i++) {
            if (auditableCompanies[auditableCompaniesAddresses[i]].state == StateType.Approved) {
                countApproved++;
            }
        }

        Company[] memory companies = new Company[](countApproved);
        uint counter = 0;

        for (uint i = 0; i < length && countApproved > 0; i++) {
            if (auditableCompanies[auditableCompaniesAddresses[i]].state == StateType.Approved) {
                companies[counter] = auditableCompanies[auditableCompaniesAddresses[i]];
                counter++;
                countApproved--;
            }
        }

        return companies;
    }

    function CompanyChangeState(CompanyType _companyType, address _company, StateType _newState, string memory _message) internal {
        require(
            msg.sender == admin,
            "You must be the administrator to change state"
        );

        if (_companyType == CompanyType.Audit) {
            auditCompanies[_company].state = _newState;
            auditCompanies[_company].changeStateMessage = _message;
            emit AuditCompanyStateChanged(auditCompanies[_company].name, _newState);
        } else {
            auditableCompanies[_company].state = _newState;
            auditableCompanies[_company].changeStateMessage = _message;
            emit AuditableCompanyStateChanged(auditableCompanies[_company].name, _newState);
        }
    }

    function ApproveAuditCompany(address _company) external {
        require (
            auditCompanies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            auditCompanies[_company].state != StateType.Approved,
            "The company is already approved"
        );

        CompanyChangeState(CompanyType.Audit, _company, StateType.Approved, "You admision was approved");
    }

    function RejectAuditCompany(address _company, string memory _message) external {
        require (
            auditCompanies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            auditCompanies[_company].state != StateType.Rejected,
            "The company is already rejected"
        );

        CompanyChangeState(CompanyType.Audit, _company, StateType.Rejected, _message);
    }

    function ApproveAuditableCompany(address _company) external {
        require (
            auditableCompanies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            auditableCompanies[_company].state != StateType.Approved,
            "The company is already rejected"
        );

        CompanyChangeState(CompanyType.Auditable, _company, StateType.Approved, "You admision was approved");
    }

    function RejectAuditableCompany(address _company, string memory _message) external {
        require (
            auditableCompanies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            auditableCompanies[_company].state != StateType.Rejected,
            "The company is already rejected"
        );

        CompanyChangeState(CompanyType.Auditable, _company, StateType.Rejected, _message);
    }

    /* Auditing Companies */

    function IsRegisteredAsAuditCompany() external view returns (bool) {
        return auditCompanies[msg.sender].account != address(0x0);
    }

    function AuditCompanyRequestAdmision(string memory _companyName) external {
        require (
            auditCompanies[msg.sender].account == address(0x0),
            "The company is already registered"
        );
        
        StateType currentState = StateType.Pending;
        uint[] memory auditReference;
        auditCompanies[msg.sender] = Company(msg.sender, _companyName, currentState, "", auditReference);
        auditCompaniesAddresses.push(msg.sender);
        emit AuditCompanyStateChanged(_companyName, currentState);
    }

    function AuditCompanyState() external view returns (StateType) {
        require (
            auditCompanies[msg.sender].account != address(0x0),
            "The company is not registered"
        );

        return auditCompanies[msg.sender].state;
    }

    function SubmitAudit(address _auditableCompany, string memory _finding) external {
        require (
            auditCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );
        require (
            auditableCompanies[_auditableCompany].account != address(0x0),
            "The auditable company is not registered"
        );
        require (
            auditCompanies[msg.sender].state == StateType.Approved,
            "The audit company is not approved"
        );
        require (
            auditableCompanies[_auditableCompany].state == StateType.Approved,
            "The auditable company is not approved"
        );
        require (
            msg.sender != _auditableCompany,
            "You can't audit yourself"
        );

        auditsCounter++;

        audits.push(Audit(
                auditsCounter,
                msg.sender, 
                _auditableCompany, 
                AuditState.Submitted, 
                _finding));

        auditCompanies[msg.sender].auditReference.push(auditsCounter - 1);
        auditableCompanies[_auditableCompany].auditReference.push(auditsCounter - 1);
        emit AuditSubmitted(audits[auditsCounter - 1]);
    }

    function getAuditCompanyRegister() external view returns (Company memory) {
        require (
            auditCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );

        return auditCompanies[msg.sender];
    }

    /* Auditable Companies */

    function IsRegisteredAsAuditableCompany() external view returns (bool) {
        return auditableCompanies[msg.sender].account != address(0x0);
    }

    function AuditableCompanyRequestAdmision(string memory _companyName) external {
        require (
            auditableCompanies[msg.sender].account == address(0x0),
            "The company is already registered"
        );
        
        StateType currentState = StateType.Pending;
        uint[] memory auditReference;
        auditableCompanies[msg.sender] = Company(msg.sender, _companyName, currentState, "", auditReference);
        auditableCompaniesAddresses.push(msg.sender);
        emit AuditableCompanyStateChanged(_companyName, currentState);
    }

    function AuditableCompanyState() external view returns (StateType) {
        require (
            auditableCompanies[msg.sender].account != address(0x0),
            "The company is not registered"
        );

        return auditableCompanies[msg.sender].state;
    }

    function getAuditableCompanyRegister() external view returns (Company memory) {
        require (
            auditableCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );

        return auditableCompanies[msg.sender];
    }

    function getAuditableCompanySubmittedAudits() external view returns (Audit[] memory) {
        require (
            auditableCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );
        require (
            auditableCompanies[msg.sender].state == StateType.Approved,
            "The auditable company is not approved"
        );

        Company storage company = auditableCompanies[msg.sender];
        uint[] storage ids = company.auditReference;
        
        uint countPending = 0;

        for (uint i = 0; i < ids.length; i++) {
            if (audits[i].state == AuditState.Submitted) {
                countPending++;
            }
        }

        Audit[] memory pendingAudits = new Audit[](countPending);
        uint counter = 0;

        for (uint i = 0; i < ids.length && countPending > 0; i++) {
            if (audits[i].state == AuditState.Submitted) {
                pendingAudits[counter] = audits[i];
                counter++;
                countPending--;
            }
        }

        return pendingAudits;
    }

    function AuditableCompanyApproveSubmittedAudit(uint id) external {
        require (
            auditableCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );
        require (
            auditableCompanies[msg.sender].state == StateType.Approved,
            "The auditable company is not approved"
        );
        require (
            id < audits.length,
            "The audit id does not exist"
        );
        require (
            audits[id].state == AuditState.Submitted,
            "The audit is already approved o rejected"
        );

        audits[id - 1].state = AuditState.Approved;
        emit AuditSubmittedStateChanged(audits[id - 1]);
    }

    function AuditableCompanyRejectSubmittedAudit(uint id) external {
        require (
            auditableCompanies[msg.sender].account != address(0x0),
            "The audit company is not registered"
        );
        require (
            auditableCompanies[msg.sender].state == StateType.Approved,
            "The auditable company is not approved"
        );
        require (
            id < audits.length,
            "The audit id does not exist"
        );
        require (
            audits[id].state == AuditState.Submitted,
            "The audit is already approved o rejected"
        );

        audits[id - 1].state = AuditState.Rejected;
        emit AuditSubmittedStateChanged(audits[id - 1]);
    }
}