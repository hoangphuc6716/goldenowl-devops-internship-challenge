# Golden Owl DevOps Internship Technical Test


## 1. Tổng quan 

Thực hiện xây dựng một pipeline CI/CD hoàn chỉnh cho một ứng dụng Node.js, sử dụng:

- **GitHub Actions** để tự động hóa CI/CD
- **Docker** để đóng gói ứng dụng thành container
- **DockerHub** làm container registry
- **Terraform** để cấp phát hạ tầng
- **AWS EC2** làm môi trường triển khai

Khi có thay đổi được đẩy lên nhánh feature, pipeline sẽ tự động chạy kiểm tra code. Khi thay đổi được merge vào nhánh `master`, pipeline sẽ build Docker image, đẩy image lên DockerHub, sau đó triển khai lên một EC2 instance thông qua SSH.

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

<img width="1227" height="642" alt="golden-owl-overview drawio" src="https://github.com/user-attachments/assets/71067076-c19a-4cc5-8a82-7acb97fba92e" />

## Luồng hoạt động

1. **Developer → GitHub** — Lập trình viên viết code và `git push` lên GitHub Repository (nhánh feature/* hoặc main).
2. **feature/* → CI Pipeline** — Push lên nhánh feature/* kích hoạt workflow CI để kiểm tra chất lượng code.
3. **main → CD Pipeline** — Khi code được merge vào nhánh main, workflow CD  được kích hoạt  để triển khai.
4. **CD → DockerHub** — CD build Docker image của ứng dụng và push image  lên DockerHub registry.
5. **CD → AWS EC2** — CD dùng SSH kết nối vào EC2 để thực hiện lệnh deploy.
6. **DockerHub → EC2** — EC2 thực hiện `docker pull` để tải image mới nhất từ DockerHub về máy chủ.
7. **User → Ứng dụng** — Người dùng cuối truy cập ứng dụng qua HTTP tại cổng 3000 trên Public IP của EC2.

---

## 4. Quy trình CI/CD


### Chi tiết pipeline CI (`ci.yml`)

<img width="1121" height="131" alt="golden-owl-ci drawio" src="https://github.com/user-attachments/assets/6dedcddc-5107-4f3e-94d0-fbd5680380fb" />


| Bước | Job | Hành động | Mô tả |
|---|---|---|---|
| 1 | test | `npm ci` | Cài đặt dependencies |
| 2 | test | `npm run lint:check` | ESLint - kiểm tra chất lượng code |
| 3 | test | `npm run format:check` | Prettier - kiểm tra định dạng code |
| 4 | test | `npm test` | Jest - chạy unit test |
| 5 | build | `docker build` | Build Docker image |
| 6 | build | `docker run` + `curl` | Smoke test - kiểm tra container hoạt động đúng |

**Điều kiện kích hoạt:** push lên nhánh `feature/**`, `feat/**`, `develop`; hoặc mở pull request vào `master`, `develop`.

**Pipeline CI chạy thành công trên tab Actions:**
<img width="1917" height="645" alt="Screenshot 2026-07-16 173222" src="https://github.com/user-attachments/assets/d401283a-eac2-42e6-9685-3eeb267ab4f1" />



### Chi tiết pipeline CD (`cd.yml`)

<img width="1099" height="340" alt="golden-owl-cd drawio (1)" src="https://github.com/user-attachments/assets/67812aa3-9b7c-4850-b91b-e618b25fcb12" />

| Bước | Job | Hành động | Mô tả |
|---|---|---|---|
| 1 | test | `npm test` | Chạy lại test trước khi triển khai |
| 2 | push | `docker/build-push-action` | Build và đẩy image lên DockerHub |
| 3 | push | Gắn tag `:latest` và `:sha` | Hai tag để quản lý phiên bản |
| 4 | deploy | `appleboy/ssh-action` | Kết nối SSH vào EC2 |
| 5 | deploy | `docker pull` → `stop` → `rm` → `run` | Thay thế container đang chạy bằng phiên bản mới |

**Điều kiện kích hoạt:** push lên nhánh `master`.

**Pipeline CD chạy thành công trên tab Actions:**

<img width="1916" height="677" alt="Screenshot 2026-07-16 174132" src="https://github.com/user-attachments/assets/5c7cff0b-6596-4907-b9d1-1b10998ebecf" />


---

## 5. Đóng gói ứng dụng bằng Docker


**Docker image đã được đẩy lên DockerHub:**

<img width="1568" height="312" alt="Screenshot 2026-07-16 171604" src="https://github.com/user-attachments/assets/8b9a25ee-7edb-4f61-b21e-0464bbd6c795" />


---

## 6. Hạ tầng dưới dạng mã nguồn (Terraform)

### Cấu trúc thư mục

```
terraform/
├── main.tf             # Provider + Security Group + EC2 Instance
├── variables.tf        # Biến đầu vào 
├── outputs.tf          # EC2 Public IP + App URL
└── terraform.tfvars    # Giá trị các biến 
```

**Kết quả chạy `terraform apply`:**

<img width="1252" height="306" alt="image" src="https://github.com/user-attachments/assets/c4efd7d0-ba68-4a88-946a-aa530429a94b" />


**EC2 instance đang chạy trên AWS Console:**

<img width="1917" height="850" alt="image" src="https://github.com/user-attachments/assets/158e1ecf-1bc1-4362-8bbd-07d89878e11f" />


### Script khởi tạo EC2 

Khi EC2 instance được khởi tạo, script `user_data` tự động thực hiện:

1. Cập nhật các gói hệ thống
2. Cài đặt Docker
3. Bật dịch vụ Docker
4. Pull image ứng dụng từ DockerHub
5. Chạy container với tùy chọn `--restart unless-stopped`

---


##  7. Cấu trúc thư mục dự án
<img width="598" height="842" alt="image" src="https://github.com/user-attachments/assets/53237f86-052a-44c5-a585-e3903fad758a" />


## 8. Hướng dẫn chạy thử

### Chạy ứng dụng ở môi trường local

```bash
cd src
npm install
npm test                 
npm start                
```
<img width="972" height="651" alt="image" src="https://github.com/user-attachments/assets/76c96682-1f87-437e-b664-5e8a313c00c9" />

<img width="971" height="663" alt="image" src="https://github.com/user-attachments/assets/c5aa9ffb-9dcf-4dd1-8ee9-c0e34c2e244f" />

<img width="978" height="157" alt="image" src="https://github.com/user-attachments/assets/1b3166ce-001a-41fb-af68-e9922309dbf9" />

### Chạy bằng Docker

```bash
docker build -t goldenowl-app .
docker run -d -p 3000:3000 --name app goldenowl-app
curl localhost:3000      
```
<img width="1206" height="623" alt="image" src="https://github.com/user-attachments/assets/3750543d-31f1-4921-a08e-c0bf23f67b17" />
<img width="1177" height="190" alt="image" src="https://github.com/user-attachments/assets/69b07e85-ea10-45eb-bfce-99e0334cfc89" />

### Triển khai lên AWS bằng Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply         
```
<img width="1252" height="306" alt="image" src="https://github.com/user-attachments/assets/237280c1-4796-4d2e-bdc2-5f230b441028" />


### Kích hoạt CI/CD

```bash
# CI
git checkout -b feature/my-feature
git push origin feature/my-feature

# CD
git checkout main
git merge feature/my-feature
git push origin main      
```

### Kiểm tra kết quả triển khai

```bash
curl http://<EC2_PUBLIC_IP>:3000
# {"message":"Welcome warriors to Golden Owl!"}
```

**Kết quả gọi `curl` đến địa chỉ EC2 public:**
<img width="1916" height="232" alt="Screenshot 2026-07-16 203559" src="https://github.com/user-attachments/assets/6d56a741-5586-4981-a71f-3c8604b35f44" />



