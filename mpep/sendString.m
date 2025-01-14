function sendString(socket, buf, dest, port)
%SENDSTRINGG Send string down a socket as a single packet.
% buf: packet contents
% dest: packet destination (ip address)
% port: destination port
import java.net.*;
disp(['Sending "' buf '"' ' to ' dest ':' num2str(port)]);
packet = DatagramPacket(java.lang.String(buf).getBytes(), ...
    int32(length(buf)), InetAddress.getByName(dest), int32(port));
socket.send(packet);
end

