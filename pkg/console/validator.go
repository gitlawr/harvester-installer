package console

import (
	"fmt"
	"net"

	"github.com/pkg/errors"
	"github.com/rancher/harvester-installer/pkg/config"
	"github.com/sirupsen/logrus"
)

var (
	ErrMsgModeCreateContainsServerURL   = fmt.Sprintf("ServerURL need to be empty in %s mode", modeCreate)
	ErrMsgModeJoinServerURLNotSpecified = fmt.Sprintf("ServerURL can't empty in %s mode", modeJoin)
	ErrMsgModeUnknown                   = "Unknown mode"
	ErrMsgTokenNotSpecified             = "token not specified"

	ErrMsgMgmtInterfaceNotSpecified = "no management interface specified"
	ErrMsgMgmtInterfaceNotFoud      = "interface not found"
	ErrMsgMgmtInterfaceIsLoop       = "interface is a loopbck interface"
	ErrMsgDeviceNotSpecified        = "no device specified"
	ErrMsgDeviceNotFound            = "device not found"
	ErrMsgNoCredentials             = "no SSH authorized keys or passwords are set"
)

type ValidatorInterface interface {
	Validate(cfg *config.HarvesterConfig) error
}

type ConfigValidator struct {
}

func prettyError(errMsg string, value string) error {
	return errors.Errorf("%s: %s", errMsg, value)
}

func checkMgmtInterface(name string) error {
	if name == "" {
		return errors.New(ErrMsgMgmtInterfaceNotSpecified)
	}
	ifaces, err := net.Interfaces()
	if err != nil {
		return err
	}
	for _, i := range ifaces {
		if i.Name == name {
			if i.Flags&net.FlagLoopback != 0 {
				return prettyError(ErrMsgMgmtInterfaceIsLoop, name)
			}
			return nil
		}
	}
	return prettyError(ErrMsgMgmtInterfaceNotFoud, name)
}

func checkDevice(device string) error {
	if device == "" {
		return errors.New(ErrMsgDeviceNotSpecified)
	}
	options, err := getDiskOptions()
	if err != nil {
		return err
	}
	for _, option := range options {
		if device == option.Value {
			return nil
		}
	}
	return prettyError(ErrMsgDeviceNotFound, device)
}

func (v ConfigValidator) Validate(cfg *config.HarvesterConfig) error {
	if err := checkMgmtInterface(cfg.Install.MgmtInterface); err != nil {
		return err
	}
	if err := checkDevice(cfg.Install.Device); err != nil {
		return err
	}
	return nil
}

func commonCheck(cfg *config.HarvesterConfig) error {
	// modes
	switch mode := cfg.Install.Mode; mode {
	case modeUpgrade:
		return nil
	case modeCreate:
		if cfg.ServerURL != "" {
			return errors.New(ErrMsgModeCreateContainsServerURL)
		}
	case modeJoin:
		if cfg.ServerURL == "" {
			return errors.New(ErrMsgModeJoinServerURLNotSpecified)
		}
	default:
		return prettyError(ErrMsgModeUnknown, mode)
	}

	if cfg.Token == "" {
		return errors.New(ErrMsgTokenNotSpecified)
	}

	if len(cfg.SSHAuthorizedKeys) == 0 && cfg.Password == "" {
		return errors.New(ErrMsgNoCredentials)
	}
	return nil
}

func validateConfig(v ValidatorInterface, cfg *config.HarvesterConfig) error {
	logrus.Debug("Validating config: ", cfg)
	if err := commonCheck(cfg); err != nil {
		return err
	}
	return v.Validate(cfg)
}
