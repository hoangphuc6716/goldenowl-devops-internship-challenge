# Báo cáo dự án - Golden Owl DevOps Internship Technical Test

**Người thực hiện:** Hoang Phuc


## 1. Tổng quan 

Thực hiện xây dựng một pipeline CI/CD hoàn chỉnh cho một ứng dụng Node.js, sử dụng:

- **GitHub Actions** để tự động hóa CI/CD
- **Docker** để đóng gói ứng dụng thành container
- **DockerHub** làm container registry
- **Terraform** để cấp phát hạ tầng
- **AWS EC2** làm môi trường triển khai

Khi có thay đổi được đẩy lên nhánh feature, pipeline sẽ tự động chạy kiểm tra code. Khi thay đổi được merge vào nhánh `main`, pipeline sẽ build Docker image, đẩy image lên DockerHub, sau đó triển khai lên một EC2 instance thông qua SSH.

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Ứng dụng | Node.js 18, Express.js | REST API server |
| Đóng gói | Docker (multi-stage build) | Đóng gói ứng dụng thành container |
| Registry | DockerHub | Lưu trữ và phân phối Docker image |
| CI/CD | GitHub Actions | Tự động hóa pipeline |
| IaC | Terraform  | Cấp phát hạ tầng cloud |
| Cloud | AWS EC2  | Máy chủ chạy ứng dụng |

---

## 3. Kiến trúc hệ thống



### Tài nguyên AWS được cấp phát bởi Terraform

| Tài nguyên | Tên | Cấu hình |
|---|---|---|
| Security Group | `goldenowl-app-sg` | Inbound: cổng 22 (SSH), cổng 3000 (App). Outbound: mở toàn bộ |
| EC2 Instance | `goldenowl-app` | t3.micro, Ubuntu 22.04, tự động cài Docker qua user_data |

---

## 4. Quy trình CI/CD


### Chi tiết pipeline CI (`ci.yml`)

| Bước | Job | Hành động | Mô tả |
|---|---|---|---|
| 1 | test | `npm ci` | Cài đặt dependencies |
| 2 | test | `npm run lint:check` | ESLint - kiểm tra chất lượng code |
| 3 | test | `npm run format:check` | Prettier - kiểm tra định dạng code |
| 4 | test | `npm test` | Jest - chạy unit test |
| 5 | build | `docker build` | Build Docker image |
| 6 | build | `docker run` + `curl` | Smoke test - kiểm tra container hoạt động đúng |

**Điều kiện kích hoạt:** push lên nhánh `feature/**`, `feat/**`, `develop`; hoặc mở pull request vào `main`, `develop`.

**Ảnh minh chứng - Pipeline CI chạy thành công trên tab Actions:**

![Kết quả chạy CI thành công](./images/02-ci-success.png)

### Chi tiết pipeline CD (`cd.yml`)

| Bước | Job | Hành động | Mô tả |
|---|---|---|---|
| 1 | test | `npm test` | Chạy lại test trước khi triển khai |
| 2 | push | `docker/build-push-action` | Build và đẩy image lên DockerHub |
| 3 | push | Gắn tag `:latest` và `:sha` | Hai tag để quản lý phiên bản |
| 4 | deploy | `appleboy/ssh-action` | Kết nối SSH vào EC2 |
| 5 | deploy | `docker pull` → `stop` → `rm` → `run` | Thay thế container đang chạy bằng phiên bản mới |

**Điều kiện kích hoạt:** push lên nhánh `main`.

**Ảnh minh chứng - Pipeline CD chạy thành công trên tab Actions:**

![Kết quả chạy CD thành công](./images/03-cd-success.png)

---

## 5. Đóng gói ứng dụng bằng Docker


**Ảnh minh chứng - Docker image đã được đẩy lên DockerHub:**

![Docker image trên DockerHub](./images/04-dockerhub-image.png)

---

## 6. Hạ tầng dưới dạng mã nguồn (Terraform)

### Cấu trúc thư mục

```
terraform/
├── main.tf             # Provider + Security Group + EC2 Instance
├── variables.tf        # Biến đầu vào (6 biến)
├── outputs.tf          # EC2 Public IP + App URL
└── terraform.tfvars    # Giá trị các biến (tự động load)
```

**Ảnh minh chứng - Kết quả chạy `terraform apply`:**

![Kết quả terraform apply](./images/05-terraform-apply.png)

**Ảnh minh chứng - EC2 instance đang chạy trên AWS Console:**

![EC2 instance trên AWS Console](./images/06-ec2-console.png)

### Script khởi tạo EC2 (user_data)

Khi EC2 instance được khởi tạo, script `user_data` tự động thực hiện:

1. Cập nhật các gói hệ thống
2. Cài đặt Docker
3. Bật dịch vụ Docker
4. Pull image ứng dụng từ DockerHub
5. Chạy container với tùy chọn `--restart unless-stopped`

---


##  7. Cấu trúc thư mục dự án


## 11. Hướng dẫn chạy thử

### Chạy ứng dụng ở môi trường local

```bash
cd src
npm install
npm test                  # Chạy test
npm start                 # Khởi động server tại localhost:3000
```

### Chạy bằng Docker

```bash
docker build -t goldenowl-app .
docker run -d -p 3000:3000 --name app goldenowl-app
curl localhost:3000       # {"message":"Welcome warriors to Golden Owl!"}
```

### Triển khai lên AWS bằng Terraform

```bash
cd terraform
terraform init
terraform apply           # Tạo EC2 + Security Group
# Output: app_url = "http://x.x.x.x:3000"
```

### Kích hoạt CI/CD

```bash
# CI: push lên nhánh feature
git checkout -b feature/my-feature
git push origin feature/my-feature

# CD: merge vào main
git checkout main
git merge feature/my-feature
git push origin main      # Tự động triển khai lên EC2
```

### Kiểm tra kết quả triển khai

```bash
curl http://<EC2_PUBLIC_IP>:3000
# {"message":"Welcome warriors to Golden Owl!"}
```

**Ảnh minh chứng - Kết quả gọi `curl` đến địa chỉ EC2 public:**

![Kết quả curl trả về từ EC2](./images/07-curl-result.png)



