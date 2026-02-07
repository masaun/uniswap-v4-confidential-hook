echo "Show the size of the ZK circuit..."
bb gates -b target/compliance.json | grep "circuit"

# Scheme is: ultra_honk
#         "circuit_size": 235503
