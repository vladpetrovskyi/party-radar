package rbac

import (
	"database/sql"
	"fmt"
	sqladapter "github.com/Blank-Xu/sql-adapter"
	"github.com/casbin/casbin/v2"
	"github.com/rs/zerolog"
)

func Init(db *sql.DB, log *zerolog.Logger) (enforcer *casbin.Enforcer) {
	log.Info().Msg("Setting up RBAC...")

	if db == nil {
		panic(fmt.Sprint("RBAC setup should be after DB initialisation!"))
	}

	var (
		adapter *sqladapter.Adapter
		err     error
	)

	if adapter, err = sqladapter.NewAdapter(db, "postgres", ""); err != nil {
		panic(fmt.Errorf("failed to create rbac adapter: %w", err))
	}

	if enforcer, err = casbin.NewEnforcer("rbac/model.conf", adapter); err != nil {
		panic(fmt.Errorf("failed to create rbac enforcer: %w", err))
	}

	if err = enforcer.LoadPolicy(); err != nil {
		panic(fmt.Errorf("failed to load policy from DB: %w", err))
	}

	if _, err = enforcer.AddPolicies([][]string{
		{"guest", "data", "read"}, {"user", "data", "write"}, {"admin", "data", "delete"},
	}); err != nil {
		panic(fmt.Errorf("failed to add policies to DB: %w", err))
	}

	if _, err = enforcer.AddGroupingPolicies([][]string{
		{"user", "guest"}, {"admin", "user"},
	}); err != nil {
		panic(fmt.Errorf("failed to add policies to DB: %w", err))
	}

	log.Info().Msg("RBAC set up finished.")

	return
}
