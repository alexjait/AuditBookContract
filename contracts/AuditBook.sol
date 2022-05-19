// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CompanyManager {
    enum RequestAdmissionStateEnum { Pending, Approved, Rejected }
    enum CompanyTypeEnum { Audit, Auditable }

    struct Company {
        CompanyTypeEnum companyType;
        address account;
        string name;
        RequestAdmissionStateEnum state;
        string changeStateMessage;
    }

    address[] internal companiesAddresses;
    mapping(address => Company) public companies;

    address admin;

    event CompanyStateChanged(string companyName, RequestAdmissionStateEnum actualState);

    constructor(address _admin) {
        admin = _admin;
    }

    function getAll() public view returns (Company[] memory) {
        uint length = companiesAddresses.length;
        Company[] memory companiesArray = new Company[](length);

        for (uint i = 0; i < length; i++) {
            companiesArray[i] = companies[companiesAddresses[i]];
        }

        return companiesArray;
    }

    function getApproved() external view returns (Company[] memory) {
        uint length = companiesAddresses.length;
        uint countApproved = 0;

        for (uint i = 0; i < length; i++) {
            if (companies[companiesAddresses[i]].state == RequestAdmissionStateEnum.Approved) {
                countApproved++;
            }
        }

        Company[] memory companiesArray = new Company[](countApproved);
        uint counter = 0;

        for (uint i = 0; i < length && countApproved > 0; i++) {
            if (companies[companiesAddresses[i]].state == RequestAdmissionStateEnum.Approved) {
                companiesArray[counter] = companies[companiesAddresses[i]];
                counter++;
                countApproved--;
            }
        }

        return companiesArray;
    }

    function CompanyChangeState(address sender, address _company, RequestAdmissionStateEnum _newState, string memory _message) private {
        require(
            sender == admin,
            "You must be the administrator to change state"
        );

        companies[_company].state = _newState;
        companies[_company].changeStateMessage = _message;
        emit CompanyStateChanged(companies[_company].name, _newState);
    }

    function Approve(address sender, address _company) external {
        require (
            companies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            companies[_company].state != RequestAdmissionStateEnum.Approved,
            "The company is already approved"
        );

        CompanyChangeState(sender, _company, RequestAdmissionStateEnum.Approved, "You admision was approved");
    }

    function Reject(address sender, address _company, string memory _message) external {
        require (
            companies[_company].account != address(0x0),
            "The company doesn't have a pending admission"
        );
        require (
            companies[_company].state != RequestAdmissionStateEnum.Rejected,
            "The company is already rejected"
        );

        CompanyChangeState(sender, _company, RequestAdmissionStateEnum.Rejected, _message);
    }

    function IsRegistered(address sender) external view returns (bool) {
        return companies[sender].account != address(0x0);
    }

    function RequestAdmision(address sender, string memory _companyName, CompanyTypeEnum companyType) external {
        require (
            companies[sender].account == address(0x0),
            "The company is already registered"
        );

        RequestAdmissionStateEnum currentState = RequestAdmissionStateEnum.Pending;
        companies[sender] = Company(companyType, sender, _companyName, currentState, "");
        companiesAddresses.push(sender);
        emit CompanyStateChanged(_companyName, currentState);
    }

    function CompanyState(address sender) external view returns (RequestAdmissionStateEnum) {
        require (
            companies[sender].account != address(0x0),
            "The company is not registered"
        );

        return companies[sender].state;
    }

    function getCompanyRegister(address sender) external view returns (Company memory) {
        require (
            companies[sender].account != address(0x0),
            "The company is not registered"
        );

        return companies[sender];
    }
}

contract AuditBook {
    CompanyManager auditCompanyManager;
    CompanyManager auditableCompanyManager;

    enum AuditState { Submitted, Approved, Rejected }

    struct Audit {
        uint id;
        address auditCompanies;
        address auditableCompanies;
        AuditState state;
        string finding;
    }

    address public admin;
    string public adminName;

    uint auditsCounter;
    Audit[] audits;
    mapping(address => uint[]) auditCompanyAuditsReference;
    mapping(address => uint[]) auditableCompanyAuditsReference;

    event AuditSubmitted(Audit audit);
    event AuditSubmittedStateChanged(Audit audit);

    constructor() {
        admin = msg.sender;
        auditCompanyManager = new CompanyManager(admin);
        auditableCompanyManager = new CompanyManager(admin);
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

    function getAuditCompanies() external view returns (CompanyManager.Company[] memory) {
        return auditCompanyManager.getAll();
    }

    function getAuditableCompanies() external view returns (CompanyManager.Company[] memory) {
        return auditableCompanyManager.getAll();
    }

    function getApprovedAuditableCompanies() external view returns (CompanyManager.Company[] memory) {
        return auditableCompanyManager.getApproved();
    }

    function ApproveAuditCompany(address _company) external {
        return auditCompanyManager.Approve(msg.sender, _company);
    }

    function RejectAuditCompany(address _company, string memory _message) external {
        return auditCompanyManager.Reject(msg.sender, _company, _message);
    }

    function ApproveAuditableCompany(address _company) external {
        return auditableCompanyManager.Approve(msg.sender, _company);
    }

    function RejectAuditableCompany(address _company, string memory _message) external {
        return auditableCompanyManager.Reject(msg.sender, _company, _message);
    }

    /* Auditing Companies */

    function IsRegisteredAsAuditCompany() external view returns (bool) {
        return auditCompanyManager.IsRegistered(msg.sender);
    }

    function AuditCompanyRequestAdmision(string memory _companyName) external {
        return auditCompanyManager.RequestAdmision(msg.sender, _companyName, CompanyManager.CompanyTypeEnum.Audit);
    }

    function AuditCompanyState() external view returns (CompanyManager.RequestAdmissionStateEnum) {
        return auditCompanyManager.CompanyState(msg.sender);
    }

    function SubmitAudit(address _auditableCompany, string memory _finding) external {
        require (
            auditCompanyManager.IsRegistered(msg.sender),
            "The audit company is not registered"
        );
        require (
            auditableCompanyManager.IsRegistered(_auditableCompany),
            "The auditable company is not registered"
        );
        require (
            auditCompanyManager.CompanyState(msg.sender) == CompanyManager.RequestAdmissionStateEnum.Approved,
            "The audit company is not approved"
        );
        require (
            auditableCompanyManager.CompanyState(_auditableCompany) == CompanyManager.RequestAdmissionStateEnum.Approved,
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

        auditCompanyAuditsReference[msg.sender].push(auditsCounter - 1);
        auditableCompanyAuditsReference[_auditableCompany].push(auditsCounter - 1);
        emit AuditSubmitted(audits[auditsCounter - 1]);
    }

    function getAuditCompanyRegister() external view returns (CompanyManager.Company memory) {
        return auditCompanyManager.getCompanyRegister(msg.sender);
    }

    /* Auditable Companies */

    function IsRegisteredAsAuditableCompany() external view returns (bool) {
        return auditableCompanyManager.IsRegistered(msg.sender);
    }

    function AuditableCompanyRequestAdmision(string memory _companyName) external {
        auditableCompanyManager.RequestAdmision(msg.sender, _companyName, CompanyManager.CompanyTypeEnum.Auditable);
    }

    function AuditableCompanyState() external view returns (CompanyManager.RequestAdmissionStateEnum) {
        return auditableCompanyManager.CompanyState(msg.sender);
    }

    function getAuditableCompanyRegister() external view returns (CompanyManager.Company memory) {
        return auditableCompanyManager.getCompanyRegister(msg.sender);
    }

    function getAuditableCompanySubmittedAudits() external view returns (Audit[] memory) {
        require (
            auditableCompanyManager.IsRegistered(msg.sender),
            "The auditable company is not registered"
        );
        require (
            auditableCompanyManager.CompanyState(msg.sender) == CompanyManager.RequestAdmissionStateEnum.Approved,
            "The auditable company is not approved"
        );

        uint[] storage ids = auditableCompanyAuditsReference[msg.sender];
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
            auditableCompanyManager.IsRegistered(msg.sender),
            "The auditable company is not registered"
        );
        require (
            auditableCompanyManager.CompanyState(msg.sender) == CompanyManager.RequestAdmissionStateEnum.Approved,
            "The auditable company is not approved"
        );
        require (
            id <= audits.length,
            "The audit id does not exist"
        );
        require (
            audits[id - 1].state == AuditState.Submitted,
            "The audit is already approved o rejected"
        );
        require(
            audits[id - 1].auditableCompanies == msg.sender,
            "The audit belongs to another company"
        );

        audits[id - 1].state = AuditState.Approved;
        emit AuditSubmittedStateChanged(audits[id - 1]);
    }

    function AuditableCompanyRejectSubmittedAudit(uint id) external {
        require (
            auditableCompanyManager.IsRegistered(msg.sender),
            "The auditable company is not registered"
        );
        require (
            auditableCompanyManager.CompanyState(msg.sender) == CompanyManager.RequestAdmissionStateEnum.Approved,
            "The auditable company is not approved"
        );
        require (
            id <= audits.length,
            "The audit id does not exist"
        );
        require (
            audits[id - 1].state == AuditState.Submitted,
            "The audit is already approved o rejected"
        );
        require(
            audits[id - 1].auditableCompanies == msg.sender,
            "The audit belongs to another company"
        );

        audits[id - 1].state = AuditState.Rejected;
        emit AuditSubmittedStateChanged(audits[id - 1]);
    }
}