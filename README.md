# SQLiSpotter

SQLiSpotter is a Bash script designed to automate the testing of URLs for error-based SQL injection vulnerabilities. It appends some common SQL injection payloads to each URL and checks the responses for common error patterns indicative of a SQL vulnerability. I have included common error resposnes of all possible DBMSes.

## Installation
Clone the repository:
```
git clone https://github.com/iamthefrogy/SQLiProbe.git
cd SQLiProbe
chmod +x sqli_probe.sh
```
## Usage
```
./sqli_probe.sh urls.txt
```
<img src="https://github.com/iamthefrogy/SQLiSpotter/assets/8291014/33c63584-d6c4-457a-a1d1-2d60e30da758.jpg" height=600px align="center">

## Dependencies
```
curl
Python 3 (for URL encoding)
```
