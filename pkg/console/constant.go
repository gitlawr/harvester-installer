package console

const (
	titlePanel           = "title"
	debugPanel           = "debug"
	diskPanel            = "disk"
	askCreatePanel       = "askCreate"
	serverURLPanel       = "serverUrl"
	passwordPanel        = "osPassword"
	passwordConfirmPanel = "osPasswordConfirm"
	sshKeyPanel          = "sshKey"
	tokenPanel           = "token"
	proxyPanel           = "proxy"
	networkPanel         = "network"
	cloudInitPanel       = "cloudInit"
	validatorPanel       = "validator"
	notePanel            = "note"
	confirmInstallPanel  = "confirmInstall"
	confirmUpgradePanel  = "confirmUpgrade"
	installPanel         = "install"
	upgradePanel         = "upgrade"
	footerPanel          = "footer"
	spinnerPanel         = "spinner"

	modeCreate  = "create"
	modeJoin    = "join"
	modeUpgrade = "upgrade"

	clusterTokenNote = "Note: The token is used for adding nodes to the cluster"
	serverURLNote    = "Note: Input IP/domain name of the management node"
	proxyNote        = "Note: In the form of \"http://[[user][:pass]@]host[:port]/\"."
	sshKeyNote       = "For example: https://github.com/<username>.keys"

	authorizedFile = "/home/rancher/.ssh/authorized_keys"
)
