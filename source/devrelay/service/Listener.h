#pragma once
#if defined(DEV_RELAY_SLIP) && defined(SLIP_PROTOCOL_NET)

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <regex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "Connection.h"

class Listener
{
private:
	std::string ip_address_;
	uint16_t port_;
	uint16_t response_timeout_;
	std::thread listening_thread_;

	bool is_listening_;
	bool should_start_;
	void create_connection(unsigned int socket);
	void listener_function();
	bool is_valid_ip_address(const std::string &ipAddress) { return std::regex_match(ipAddress, ipPattern); }

	static const std::regex ipPattern;

#pragma warning(push)
#pragma warning(disable: 26495) // I just want the struct without defaults. Is that so very hard.
	struct ConnectionInfo
	{
		uint8_t host_id;						// the device id given to the host for this device (sequential number from 1..255)
		uint8_t device_id;						// the actual id of the device on the device side. this allows multiple devices to attach with any number of devices, and not have clashes in AW
		std::shared_ptr<Connection> connection; // the connection established during the device registration with the listener    
	};
#pragma warning(pop)

	std::map<uint8_t, ConnectionInfo> connection_info_map_;

public:
	Listener();
	~Listener();

	void Initialize(std::string ip_address, const uint16_t port, const uint16_t response_timeout);

	void start();
	void stop();

	std::thread create_listener_thread();
	bool get_is_listening() const;

	std::pair<uint8_t, std::shared_ptr<Connection>> find_connection_with_device(const uint8_t device_id) const;
	std::vector<std::pair<uint8_t, Connection *>> get_all_connections() const;

	void insert_connection(uint8_t host_id, const ConnectionInfo& info);

	uint8_t get_total_device_count();
	void set_start_on_init(bool should_start) { should_start_ = should_start; }
	bool get_start_on_init() { return should_start_; }
	std::pair<int, int> first_two_disk_devices(std::function<bool(const std::vector<uint8_t>&)> is_disk_device) const;

	// default values for listener
	bool default_start_listener = true;
	std::string default_listener_address = "0.0.0.0";
	uint16_t default_port = 1985;
	uint16_t default_response_timeout = 10; // seconds

	std::string get_ip_address() const { return ip_address_; }
	std::string check_and_set_ip_address(const std::string &ip_address)
	{
		if (is_valid_ip_address(ip_address))
		{
			ip_address_ = ip_address;
		}
		else
		{
			ip_address_ = default_listener_address;
		}
		return ip_address_;
	}

	uint16_t get_port() const { return port_; }
	void set_port(uint16_t port) { port_ = port; }

	uint16_t get_response_timeout() const { return response_timeout_; }
	void set_response_timeout(uint16_t timeout) { response_timeout_ = timeout; }

	void connection_closed(Connection *connection);
	void add_connection_info(uint8_t key, const ConnectionInfo &info) { connection_info_map_[key] = info; }
};

extern class Listener &GetCommandListener(void);

#endif
