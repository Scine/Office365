#!/bin/bash
if [ ! -e /opt/connectwise* ]; then
cd /Users/Shared
curl -o ConnectWiseControl.ClientSetup.pkg "https://bigleaf.screenconnect.com/Bin/ConnectWiseControl.ClientSetup.pkg?h=instance-vc3w6w-relay.screenconnect.com&p=443&k=BgIAAACkAABSU0ExAAgAAAEAAQA5fDQA3G1XqgrfbpTCA7VSJNEelkNRPGD5baD2W%2Fh3C40ueJw1ewvxY%2B5CXtKXAXcovdbT6E7ujozLMEwfkALC9FKigzXijHSwQ3s5EuQjmp%2FpdbAHUSCGsnM2qcwAh32LSE%2BvC%2BlQ70AVV%2Fy%2B%2Bs%2ByQ8MqoYH0YnVvXmOEPDP%2FpHGrkeA6JuaKkZe1SDeuylLDnMXsEhqRgJz39cI2FMD%2BHDBL9tqbUqTXHTcNsglhWxa7azIkVqaKdSLcbFDNGhmZMuvPiPrqUejzW3q7OUtReUBW%2F9KKaRtlse15lcdH12DiTq1CG0i%2F0Mp4LHthlnHeZgIw1XkhXRNCpqEIGqXv&e=Access&y=Guest&t=&c=&c=&c=&c=&c=&c=&c=&c="
sudo installer -package ./ConnectWiseControl.ClientSetup.pkg -target / && sudo rm ./ConnectWiseControl.ClientSetup.pkg
else
exit 0
fi