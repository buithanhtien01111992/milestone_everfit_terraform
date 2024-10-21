## Giới thiệu
Dự án này sử dụng Terraform để triển khai một ứng dụng Flask trên một EC2 instance của AWS với một RDS instance MySQL. Dự án bao gồm việc tạo các nhóm bảo mật, key pairs và các tài nguyên cần thiết khác.

## Yêu cầu
- Terraform >= 1.2.5
- AWS CLI được cài đặt và cấu hình với thông tin xác thực của bạn
- Python 3.x và pip (để phát triển ứng dụng)

## Cài đặt
1. Clone dự án về máy:
    ```bash
    git clone https://github.com/yourusername/yourproject.git
    cd yourproject
    ```

2. Tạo file `terraform.tfvars` với thông tin sau:
    ```hcl
    db_username = "your_db_username"
    db_password = "your_db_password"
    ```

3. Tạo file `private_key.pem` để sử dụng cho SSH truy cập EC2 instance. Đảm bảo rằng file này có quyền truy cập đúng:
    ```bash
    chmod 400 private_key.pem
    ```

## Cấu hình
Trong file `main.tf`, bạn có thể thay đổi các biến như `ec2_instance_type`, `db_name`, `db_username`, và `db_password` theo yêu cầu của bạn.

## Triển khai
1. Khởi tạo Terraform:
    ```bash
    terraform init
    ```

2. Kiểm tra kế hoạch triển khai:
    ```bash
    terraform plan
    ```

3. Triển khai tài nguyên:
    ```bash
    terraform apply
    ```
4. Để truy cập vào EC2 instance, sử dụng lệnh sau:
    ```bash
    ssh -i "private_key.pem" ubuntu@<EC2_PUBLIC_IP>
    ```

## Kết quả đầu ra
Sau khi triển khai thành công, bạn sẽ nhận được:
- Lệnh SSH để truy cập EC2 instance
- Endpoint của RDS instance.
- Truy cập web với đường dẫn http://<public_ip>:5000 

## Thông tin liên hệ
Nếu bạn có bất kỳ câu hỏi nào, vui lòng liên hệ với tôi qua email: buithanhtien.spkt@gmail.com
