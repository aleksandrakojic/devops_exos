package ServerPool

import "github.com/aleksandrakojic/devops_exos/load_balancer/types"

type ServerPool struct {
	servers []*types.Server
}

func NewServerPool() *ServerPool {
	return &ServerPool{
		servers: make([]*types.Server, 0),
	}
}


func (sp *ServerPool) AddServer(server *types.Server) error {
	sp.servers = append(sp.servers, server)
	return nil
}

func (sp *ServerPool) GetServers() []*types.Server {
	return sp.servers
}

func (sp *ServerPool) GetHealthyServers() []*types.Server {
	healthyServers := make([]*types.Server, 0)
	for _, server := range sp.servers {
		if server.IsHealthy {
			healthyServers = append(healthyServers, server)
		}
	}
	return healthyServers
}