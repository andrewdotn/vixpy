all:
	time sh -c 'vagrant up --parallel && for F in client1 gw1 gw2 client2 cm; do vagrant ssh $$F -c date; done && vagrant destroy -f'
