package healthchecker

import (
	"fmt"
	"log"
	"net/http"
	"time"

	server "github.com/aleksandrakojic/devops_exos/load_balancer/pool"
	"github.com/aleksandrakojic/devops_exos/load_balancer/types"
)

type HealthChecker struct {
	interval time.Duration
	pool     *server.ServerPool
}

func NewHealthChecker(interval time.Duration, pool *server.ServerPool) *HealthChecker {
	return &HealthChecker{
		interval: interval,
		pool:     pool,
	}
}

func (hc *HealthChecker) CheckServerHealth() {
	servers := hc.pool.GetServers()

	for {
		log.Print("Starting Health Check...")
		for _, server := range servers {
			if server.HealthCheckURL != "" {
				doHTTPRequest(server)
			} else {
				log.Printf("Health check URL not defined for server %s", server.Name)
			}
		}

	}

	fmt.Println()
	fmt.Println()
	fmt.Println("Server status")

	time.Sleep(hc.interval)
}

func doHTTPRequest(server *types.Server) {
	client := http.Client{}

	resp, err := client.Get(server.HealthCheckURL)
	if err != nil {
		log.Printf("Health check failed for server %s: %v", server.Name, err)
		updateServerUnhealthyStatus(server)
		return
	}
	if resp.StatusCode == http.StatusOK && !server.IsHealthy {
		updateServerHealthyStatus(server)
	}
	if resp.StatusCode != http.StatusOK && server.IsHealthy {
		updateServerUnhealthyStatus(server)
	}

}

func updateServerUnhealthyStatus(server *types.Server) {

	log.Print("Health Check Faild: Serever Unhealthy: ", server.Name)

	if server.IsHealthy {
		server.FailureCount++
	}

	if server.FailureCount >= server.UnhealthyAfter && server.IsHealthy {
		server.IsHealthy = false
	}
}

func updateServerHealthyStatus(server *types.Server) {
	server.SuccessCount++

	if server.SuccessCount >= server.HealthyAfter && !server.IsHealthy {
		server.IsHealthy = true
		server.SuccessCount = 0
		server.FailureCount = 0
	}
}


