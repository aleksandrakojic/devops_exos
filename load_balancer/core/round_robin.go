package balancer

import (
	"errors"
	"sync"

	pool "github.com/aleksandrakojic/devops_exos/load_balancer/pool"
	"github.com/aleksandrakojic/devops_exos/load_balancer/types"
)

var (
	once = sync.Once{}
)

type RoundRobinBalancer struct {
	pool *pool.ServerPool
	mu   sync.Mutex
	idx  int
}

func NewRoundRobinBalancer(pool *pool.ServerPool) *RoundRobinBalancer {
	return &RoundRobinBalancer{
		pool: pool,
		idx:  -1,
	}
}

func (rb *RoundRobinBalancer) GetNextServer() (*types.Server, error) {
	servers := rb.pool.GetServers()

	if len(servers) == 0 {
		return nil, errors.New("no servers available")
	}

	rb.mu.Lock()
	defer rb.mu.Unlock()

	rb.idx = (rb.idx + 1) % len(servers)

	selectedServer := servers[rb.idx]

	return selectedServer, nil
}
