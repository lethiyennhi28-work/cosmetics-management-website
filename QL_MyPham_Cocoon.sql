/* =============================================================
   PHẦN 1: KHỞI TẠO CƠ SỞ DỮ LIỆU & BẢNG
   ============================================================= */

USE master;
GO

-- Xóa database cũ nếu tồn tại để tạo mới sạch sẽ
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'QL_MyPham_Cocoon')
    DROP DATABASE QL_MyPham_Cocoon;
GO

CREATE DATABASE QL_MyPham_Cocoon;
GO

USE QL_MyPham_Cocoon;
GO

-- Thiết lập định dạng ngày tháng (Năm-Tháng-Ngày)
SET DATEFORMAT YMD;
GO

-- 1. Bảng LOAISANPHAM 
CREATE TABLE LOAISANPHAM (
    MaLoai VARCHAR(10) PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
);
GO

-- 2. Bảng NHACUNGCAP 
CREATE TABLE NHACUNGCAP (
    MaNCC VARCHAR(10) PRIMARY KEY,
    TenNCC NVARCHAR(50) NOT NULL,
    DiaChi NVARCHAR(100) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    Email VARCHAR(50) NOT NULL
);
GO

-- 3. Bảng SANPHAM 
-- (Đã bao gồm các cột mở rộng từ phần cập nhật: HinhAnh, GiaVon, LoaiDa để cấu trúc hoàn chỉnh ngay từ đầu)
CREATE TABLE SANPHAM (
    MaSP VARCHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(50) NOT NULL,
    Gia MONEY CHECK(Gia > 0),
    NgaySX DATE NOT NULL,
    HanSD DATE NOT NULL,
    SoLuong INT DEFAULT 0,
    MaLoai VARCHAR(10) REFERENCES LOAISANPHAM(MaLoai),
    MaNCC VARCHAR(10) REFERENCES NHACUNGCAP(MaNCC),
    -- Các cột bổ sung
    HinhAnh NVARCHAR(200) NULL,
    GiaVon MONEY DEFAULT 0,
    LoaiDa NVARCHAR(50) CHECK (LoaiDa IN (N'Da dầu', N'Da khô', N'Da nhạy cảm', N'Mọi loại da'))
);
GO

-- 4. Bảng KHACHHANG 
-- (Sử dụng phiên bản có MatKhau)
CREATE TABLE KHACHHANG (
    MaKH VARCHAR(10) PRIMARY KEY,
    HoTen NVARCHAR(50) NOT NULL,
    NgaySinh DATE NULL,
    GioiTinh NVARCHAR(3) CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    SDT VARCHAR(10) UNIQUE,
    Email VARCHAR(50) NULL,
    MatKhau VARCHAR(100) NULL, -- Cột mới
    DiaChi NVARCHAR(100) NULL
);
GO

-- 5. Bảng NHANVIEN 
-- (Sử dụng phiên bản có MaQuyen và Password MD5)
CREATE TABLE NHANVIEN (
    MaNV VARCHAR(10) PRIMARY KEY,
    HoTen NVARCHAR(50) NOT NULL,
    GioiTinh NVARCHAR(3) CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    ChucVu NVARCHAR(50) NOT NULL,
    Luong MONEY CHECK (Luong > 0),
    Username VARCHAR(30) UNIQUE NOT NULL,
    Password VARCHAR(32) NOT NULL,
    MaQuyen VARCHAR(20) -- Cột phân quyền
);
GO

-- 6. Bảng KHUYENMAI 
-- (Thêm cột SoLuongMa, MoTa từ phần cập nhật của Yến Nhi)
CREATE TABLE KHUYENMAI (
    MaKM VARCHAR(10) PRIMARY KEY,
    TenCTKM NVARCHAR(50) NOT NULL,
    TiLeGiam FLOAT CHECK (TiLeGiam <= 100 AND TiLeGiam >= 0),
    NgayBD DATE NOT NULL,
    NgayKT DATE NOT NULL,
    SoLuongMa INT DEFAULT 100, -- Cột mới
    MoTa NVARCHAR(255) NULL    -- Cột mới
);
GO

-- 7. Bảng HOADON 
-- (Thêm cột TrangThai, MaKM từ phần cập nhật)
CREATE TABLE HOADON (
    MaHD VARCHAR(10) PRIMARY KEY,
    NgayLap DATE DEFAULT GETDATE(),
    MaNV VARCHAR(10) REFERENCES NHANVIEN(MaNV),
    MaKH VARCHAR(10) REFERENCES KHACHHANG(MaKH),
    TongTien MONEY CHECK (TongTien >= 0),
    TrangThai NVARCHAR(50) DEFAULT N'Chờ duyệt', -- Cột mới
    MaKM VARCHAR(10) REFERENCES KHUYENMAI(MaKM)   -- Cột mới
);
GO

-- 8. Bảng CHITIETHOADON 
CREATE TABLE CHITIETHOADON (
    MaHD VARCHAR(10) REFERENCES HOADON(MaHD),
    MaSP VARCHAR(10) REFERENCES SANPHAM(MaSP),
    SoLuong INT CHECK (SoLuong > 0),
    DonGia MONEY CHECK (DonGia >= 0),
    ThanhTien MONEY CHECK (ThanhTien >= 0),
    PRIMARY KEY (MaHD, MaSP)
);
GO

-- 9. Bảng PHUONGTHUCTHANHTOAN 
CREATE TABLE PHUONGTHUCTHANHTOAN (
    MaPT VARCHAR(10) PRIMARY KEY,
    TenPT NVARCHAR(50) NOT NULL
);
GO

-- 10. Bảng TONKHO 
CREATE TABLE TONKHO (
    MaSP VARCHAR(10) PRIMARY KEY REFERENCES SANPHAM(MaSP),
    SoLuongTon INT DEFAULT 0,
    NgayCapNhat DATE DEFAULT GETDATE()
);
GO

-- 11. Bảng phụ trợ cho Trigger (NHATKY_GIA)
CREATE TABLE NHATKY_GIA (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaSP VARCHAR(10),
    GiaCu MONEY,
    GiaMoi MONEY,
    NgayThayDoi DATETIME DEFAULT GETDATE()
);
GO

/* =============================================================
   PHẦN 2: NHẬP DỮ LIỆU MẪU
   ============================================================= */

-- 1. LOAISANPHAM 
INSERT INTO LOAISANPHAM (MaLoai, TenLoai) VALUES 
('LI001', N'Chống nắng'),
('LI002', N'Tẩy trang'),
('LI003', N'Kem dưỡng'),
('LI004', N'Tinh chất'),
('LI005', N'Mặt nạ'),
('LI006', N'Nước cân bằng'),
('LI007', N'Tẩy da chết mặt');
GO

-- 2. NHACUNGCAP 
INSERT INTO NHACUNGCAP (MaNCC, TenNCC, DiaChi, SDT, Email) VALUES
('NCC01', N'Công ty TNHH Nature Story', N'Khu công nghiệp Xuyên Á, Xã Mỹ Hạnh Bắc, Huyện Đức Hoà, Tỉnh Long An', '19009300', 'we@cocoonvietnam.com'),
('NCC02', N'Croda Vietnam', N'Số 106 đường Nguyễn Văn Trỗi, Phường 08, Quận Phú Nhuận, Thành phố Hồ Chí Minh', '02838479963', 'vietnam@croda.com'),
('NCC03', N'Công ty Cổ phần Y&B', N'Phường Tân Thới Hiệp, Quận 12, Thành phố Hồ Chí Minh', '02838328228', 'contact@yb.com.vn'),
('NCC04', N'Công ty TNHH Paltac', N'Phường Bến Thành, Quận 1, Thành phố Hồ Chí Minh', '09069801232', 'info@paltacvn.com');
GO

-- 3. SANPHAM (Chỉ nhập các cột cơ bản trước, các cột mới sẽ update sau hoặc để null)
INSERT INTO SANPHAM (MaSP, TenSP, Gia, NgaySX, HanSD, SoLuong, MaLoai, MaNCC) VALUES
('SP001', N'Kem chống nắng bí đao 50ml', 388000, '2025-09-18', '2026-09-18', 100, 'LI001', 'NCC01'),
('SP002', N'Nước tẩy trang hoa hồng 140ml', 153000, '2025-09-05', '2026-03-05', 150, 'LI002', 'NCC02'),
('SP003', N'Thạch hoa hồng dưỡng ẩm 100ml', 378000, '2025-09-03', '2026-06-03', 120, 'LI003', 'NCC02'),
('SP004', N'Tinh chất nghệ Hưng Yên C22 30ml', 457000, '2025-09-18', '2026-06-18', 200, 'LI004', 'NCC03'),
('SP005', N'Mặt nạ nghệ Hưng Yên 100ml', 339000, '2025-09-18', '2026-09-18', 100, 'LI005', 'NCC04'),
('SP006', N'Nước sen Hậu Giang 500ml', 418000, '2025-09-05', '2026-09-05', 140, 'LI006', 'NCC02'),
('SP007', N'Nước bí đao cân bằng da 310ml', 290000, '2025-09-06', '2026-03-06', 150, 'LI006', 'NCC04'),
('SP008', N'Cà phê Đắk Lắk làm sạch da chết mặt 150ml', 162000, '2025-09-06', '2026-09-06', 50, 'LI007', 'NCC01'),
('SP009', N'Sáp dưỡng ẩm đa năng sen Hậu Giang 30ml', 192000, '2025-09-09', '2026-06-09', 100, 'LI003', 'NCC02'),
('SP010', N'Dầu tẩy trang hoa hồng 310ml', 339000, '2025-09-10', '2026-09-10', 125, 'LI002', 'NCC04');
GO

-- 4. KHACHHANG (Dữ liệu có mật khẩu MD5)
INSERT INTO KHACHHANG (MaKH, HoTen, NgaySinh, GioiTinh, SDT, Email, MatKhau, DiaChi) VALUES
('KH001', N'Nguyễn Thị Mai', '2000-05-12', N'Nữ', '0905123456', 'mainguyen@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '123456'), 2), N'Q.1, TP. HCM'),
('KH002', N'Trần Văn An', '1998-11-20', N'Nam', '0912345678', 'an.tran98@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '123'), 2), N'Bình Thạnh, TP. HCM'),
('KH003', N'Lê Thảo Nhi', '2002-03-05', N'Nữ', '0923456789', 'lethaonhi@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '1256'), 2), N'Q.7, TP. HCM'),
('KH004', N'Phạm Quốc Huy', '1999-07-15', N'Nam', '0934567890', 'huypham@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '126'), 2), N'Thủ Đức, TP. HCM'),
('KH005', N'Vũ Thị Hồng', '2001-12-01', N'Nữ', '0945678901', 'vuhong01@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '12346'), 2), N'Gò Vấp, TP. HCM'),
('KH006', N'Đỗ Minh Khoa', '1997-06-22', N'Nam', '0956789012', 'khoado97@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '156'), 2), N'Q.3, TP. HCM'),
('KH007', N'Nguyễn Lan Hương', '2003-01-09', N'Nữ', '0967890123', 'huonglan@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '1456'), 2), N'Q.10, TP. HCM'),
('KH008', N'Trịnh Văn Phúc', '1996-09-18', N'Nam', '0978901234', 'phuc.trinh@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '1556'), 2), N'Q.5, TP. HCM'),
('KH009', N'Lâm Bảo Ngọc', '2002-08-30', N'Nữ', '0989012345', 'ngoc.lam@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '1888'), 2), N'Q.12, TP. HCM'),
('KH010', N'Hoàng Anh Tuấn', '1995-04-27', N'Nam', '0990123456', 'tuan.anh@gmail.com', CONVERT(VARCHAR(32), HashBytes('MD5', '123478'), 2), N'Tân Bình, TP. HCM');
GO

-- 5. NHANVIEN (Dữ liệu có mật khẩu MD5)
INSERT INTO NHANVIEN (MaNV, HoTen, GioiTinh, ChucVu, Luong, Username, Password) VALUES
('NV001', N'Nguyễn Văn An', N'Nam', N'Nhân viên', 8000000, 'an.nguyen', 'an123'),
('NV002', N'Trần Thị Bình', N'Nữ', N'Nhân viên', 7500000, 'binh.tran', 'binh123'),
('NV003', N'Lê Văn Cường', N'Nam', N'Trưởng phòng', 15000000, 'cuong.le', 'cuong123'),
('NV004', N'Phạm Thị Dung', N'Nữ', N'Nhân viên', 7000000, 'dung.pham', 'dung123'),
('NV005', N'Hoàng Văn Đông', N'Nam', N'Nhân viên', 9000000, 'dong.hoang', 'dong123'),
('NV006', N'Phạm Thị Hồng', N'Nữ', N'Kế toán', 12000000, 'hong.pham', 'ha123'),
('NV007', N'Nguyễn Văn Hùng', N'Nam', N'Giám đốc', 30000000, 'hung.nguyen', 'hung123'),
('NV008', N'Nguyễn Thị Nga', N'Nữ', N'Nhân viên', 8500000, 'nga.nguyen', 'lan123'),
('NV009', N'Bùi Văn Minh', N'Nam', N'Phó phòng', 18000000, 'minh.bui', 'minh123'),
('NV010', N'Ngô Thị Oanh', N'Nữ', N'Nhân viên', 8200000, 'oanh.ngo', 'oanh123');
GO

-- Cập nhật mật khẩu mã hóa và MaQuyen cho nhân viên
UPDATE NHANVIEN SET MaQuyen = 'Role_GiamDoc', Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'hung123'), 2) WHERE MaNV = 'NV007';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'cuong123'), 2) WHERE MaNV = 'NV003';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'an123'), 2) WHERE MaNV = 'NV001';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'binh123'), 2) WHERE MaNV = 'NV002';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'dung123'), 2) WHERE MaNV = 'NV004';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'dong123'), 2) WHERE MaNV = 'NV005';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'ha123'), 2) WHERE MaNV = 'NV006';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'lan123'), 2) WHERE MaNV = 'NV008';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'minh123'), 2) WHERE MaNV = 'NV009';
UPDATE NHANVIEN SET Password = CONVERT(VARCHAR(32), HashBytes('MD5', 'oanh123'), 2) WHERE MaNV = 'NV010';
GO

-- 6. HOADON 
INSERT INTO HOADON (MaHD, NgayLap, MaNV, MaKH, TongTien) VALUES
('HD001', '2023-01-05', 'NV001', 'KH001', 1541000),
('HD002', '2022-01-10', 'NV002', 'KH002', 2625000),
('HD003', '2023-01-15', 'NV003', 'KH003', 756000),
('HD004', '2020-01-20', 'NV004', 'KH004', 1356000),
('HD005', '2023-02-01', 'NV005', 'KH005', 960000),
('HD006', '2024-02-08', 'NV006', 'KH006', 2712000),
('HD007', '2023-02-15', 'NV007', 'KH007', 1160000),
('HD008', '2019-02-20', 'NV008', 'KH008', 1296000);
GO

-- 7. CHITIETHOADON 
INSERT INTO CHITIETHOADON (MaHD, MaSP, SoLuong, DonGia, ThanhTien) VALUES
('HD001', 'SP001', 2, 388000, 776000),
('HD001', 'SP002', 5, 153000, 765000),
('HD002', 'SP004', 3, 457000, 1371000),
('HD002', 'SP006', 3, 418000, 1254000),
('HD003', 'SP003', 2, 378000, 756000),
('HD004', 'SP005', 4, 339000, 1356000),
('HD005', 'SP009', 5, 192000, 960000),
('HD006', 'SP010', 8, 339000, 2712000),
('HD007', 'SP007', 4, 290000, 1160000),
('HD008', 'SP008', 8, 162000, 1296000);
GO

-- 8. KHUYENMAI 
INSERT INTO KHUYENMAI (MaKM, TenCTKM, TiLeGiam, NgayBD, NgayKT) VALUES
('KM001', N'Da xinh deal xịn', 25, '2025-09-18', '2025-09-25'),
('KM002', N'Chạm là cưng - Ưu đãi liền tay', 15, '2025-07-01', '2025-07-08'),
('KM003', N'Làn da ngọc - Giá ngon ngọc', 30, '2025-07-15', '2025-07-18'),
('KM004', N'Mịn màng rạng ngời - Mua 1 tặng 1', 100, '2025-09-21', '2025-09-22'),
('KM005', N'Chăm da chuẩn spa', 20, '2025-08-17', '2025-08-24'),
('KM006', N'Săn skincare', 40, '2025-10-01', '2025-10-03'),
('KM007', N'Bí quyết đẹp da mặt', 10, '2025-09-01', '2025-09-30'),
('KM008', N'Glow up thần tốc', 50, '2025-09-28', '2025-09-30'),
('KM009', N'Tươi tắn mỗi ngày', 5, '2025-08-01', '2025-09-30'),
('KM010', N'Love your face - Yêu da giá yêu', 45, '2025-10-18', '2025-10-22');
GO

-- 9. PHUONGTHUCTHANHTOAN 
INSERT INTO PHUONGTHUCTHANHTOAN (MaPT, TenPT) VALUES
('PT001', N'Tiền mặt'),
('PT002', N'Chuyển khoản ngân hàng'),
('PT003', N'Ví điện tử'),
('PT004', N'Thanh toán QR Code'),
('PT005', N'Thẻ tín dụng/ghi nợ'),
('PT006', N'Thanh toán khi nhận hàng'),
('PT007', N'Thanh toán qua ứng dụng thương mại điện tử');
GO

-- 10. TONKHO (Data ban đầu)
INSERT INTO TONKHO (MaSP, SoLuongTon, NgayCapNhat) VALUES
('SP001', 13, '2025-09-19'),
('SP002', 19, '2025-09-19'),
('SP003', 27, '2025-09-19'),
('SP004', 121, '2025-09-19'),
('SP005', 34, '2025-09-19'),
('SP006', 90, '2025-09-19'),
('SP007', 10, '2025-09-19'),
('SP008', 10, '2025-09-19'),
('SP009', 50, '2025-09-19'),
('SP010', 43, '2025-09-19');
GO

/* =============================================================
   PHẦN 3: CẬP NHẬT DỮ LIỆU & SCHEMA NÂNG CAO (GỘP CÁC PHẦN CẬP NHẬT)
   ============================================================= */

-- 1. Cập nhật Hình ảnh sản phẩm
UPDATE SANPHAM SET HinhAnh = 'bi_dao.jpg' WHERE MaSP = 'SP001';
UPDATE SANPHAM SET HinhAnh = 'tay_trang_hoa_hong.jpg' WHERE MaSP = 'SP002';
UPDATE SANPHAM SET HinhAnh = 'thach_hoa_hong.jpg' WHERE MaSP = 'SP003';
UPDATE SANPHAM SET HinhAnh = 'tinh_chat_nghe.jpg' WHERE MaSP = 'SP004';
UPDATE SANPHAM SET HinhAnh = 'mat_na_nghe.jpg' WHERE MaSP = 'SP005';
UPDATE SANPHAM SET HinhAnh = 'nuoc_sen.jpg' WHERE MaSP = 'SP006';
UPDATE SANPHAM SET HinhAnh = 'nuoc_bi_dao.jpg' WHERE MaSP = 'SP007';
UPDATE SANPHAM SET HinhAnh = 'cafe_daklak.jpg' WHERE MaSP = 'SP008';
UPDATE SANPHAM SET HinhAnh = 'sap_duong_am.jpg' WHERE MaSP = 'SP009';
UPDATE SANPHAM SET HinhAnh = 'dau_tay_trang.jpg' WHERE MaSP = 'SP010';
GO

-- 2. Cập nhật Loại Da (Phần của Yến Nhi)
UPDATE SANPHAM SET LoaiDa = N'Da dầu' WHERE MaSP IN ('SP001', 'SP007');
UPDATE SANPHAM SET LoaiDa = N'Da khô' WHERE MaSP IN ('SP003', 'SP009');
UPDATE SANPHAM SET LoaiDa = N'Mọi loại da' WHERE LoaiDa IS NULL;
GO

-- 3. Cập nhật Trạng thái hóa đơn cũ
UPDATE HOADON SET TrangThai = N'Hoàn tất';
GO

-- 4. Thêm mã khuyến mãi mới (Phần của Yến Nhi)
INSERT INTO KHUYENMAI (MaKM, TenCTKM, TiLeGiam, NgayBD, NgayKT, SoLuongMa) 
VALUES ('COCOON2025', N'Ưu đãi năm mới', 10, '2024-01-01', '2025-12-31', 50);
INSERT INTO KHUYENMAI (MaKM, TenCTKM, TiLeGiam, NgayBD, NgayKT, SoLuongMa) 
VALUES ('COCOON20', N'Ưu đãi năm mới 2', 20, '2024-01-01', '2025-12-31', 50);
INSERT INTO KHUYENMAI (MaKM, TenCTKM, TiLeGiam, NgayBD, NgayKT, SoLuongMa) 
VALUES ('COCOON50', N'Ưu đãi năm mới 3', 50, '2024-01-01', '2025-12-31', 50);
GO

-- 5. Đồng bộ Tồn kho & Giá vốn (Phần của Duyên)
-- Cập nhật cột SoLuong trong bảng SANPHAM bằng với TONKHO
UPDATE SANPHAM
SET SoLuong = T.SoLuongTon
FROM SANPHAM S
INNER JOIN TONKHO T ON S.MaSP = T.MaSP;

-- Tự động thêm vào TONKHO những sản phẩm thiếu
INSERT INTO TONKHO (MaSP, SoLuongTon, NgayCapNhat)
SELECT MaSP, SoLuong, GETDATE()
FROM SANPHAM
WHERE MaSP NOT IN (SELECT MaSP FROM TONKHO);

-- Cập nhật giá vốn giả định (60% giá bán)
UPDATE SANPHAM
SET GiaVon = Gia * 0.6;
GO

/* =============================================================
   PHẦN 4: FUNCTION (HÀM)
   ============================================================= */

-- 1. fn_TongTienHD 
CREATE FUNCTION fn_TongTienHD(@MaHD VARCHAR(10)) RETURNS MONEY 
AS
BEGIN
    RETURN (SELECT ISNULL(SUM(ThanhTien), 0) FROM CHITIETHOADON WHERE MaHD=@MaHD);
END;
GO

-- 2. fn_TiLeKMHienHanh 
CREATE FUNCTION fn_TiLeKMHienHanh (@Ngay DATE)
RETURNS FLOAT
AS
BEGIN
    DECLARE @TiLe FLOAT;
    SELECT @TiLe = MAX(TiLeGiam) FROM KHUYENMAI WHERE @Ngay BETWEEN NgayBD AND NgayKT;
    IF (@TiLe IS NULL) SET @TiLe = 0;
    RETURN @TiLe;
END
GO

-- 3. fn_DoanhThuNV 
CREATE FUNCTION fn_DoanhThuNV (@MaNV VARCHAR(10), @Tu DATE, @Den DATE) RETURNS MONEY 
AS
BEGIN
    DECLARE @DoanhThu MONEY;
    SELECT @DoanhThu = SUM(TongTien) FROM HOADON WHERE MaNV = @MaNV AND NgayLap BETWEEN @Tu AND @Den;
    IF (@DoanhThu IS NULL) SET @DoanhThu = 0;
    RETURN @DoanhThu;
END
GO

-- 4. fn_TonKhaDung 
CREATE FUNCTION fn_TonKhaDung(@MaSP VARCHAR(10)) RETURNS INT 
AS
BEGIN
    DECLARE @Ton INT;
    SELECT @Ton = SoLuongTon FROM TONKHO WHERE MaSP = @MaSP;
    IF (@Ton IS NULL) SET @Ton = 0;
    RETURN @Ton;
END;
GO

-- 5. fn_DonGiaSauKM 
CREATE FUNCTION fn_DonGiaSauKM (@DonGia MONEY, @Ngay DATE)
RETURNS MONEY
AS
BEGIN
    DECLARE @Tile FLOAT = 0
    DECLARE @Gia MONEY
    SELECT TOP 1 @Tile = TiLeGiam FROM KHUYENMAI WHERE @Ngay BETWEEN NgayBD AND NgayKT
    SET @Gia = @DonGia * (1 - ISNULL(@Tile,0)/100)
    IF @Gia < 0 SET @Gia = 0
    RETURN @Gia
END
GO

-- 6. fn_DoanhThuThucTe (Phần của Yến Nhi)
CREATE FUNCTION fn_DoanhThuThucTe (@TuNgay DATE, @DenNgay DATE)
RETURNS MONEY
AS
BEGIN
    DECLARE @Tong MONEY;
    SELECT @Tong = SUM(TongTien) 
    FROM HOADON 
    WHERE NgayLap BETWEEN @TuNgay AND @DenNgay 
      AND TrangThai = N'Hoàn tất';
    RETURN ISNULL(@Tong, 0);
END
GO

/* =============================================================
   PHẦN 5: TRIGGER
   ============================================================= */

-- 1. trg_CapNhatTonKho (Khi bán hàng - Insert Chi tiết hóa đơn)
CREATE TRIGGER trg_CapNhatTonKho ON CHITIETHOADON AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra sản phẩm tồn tại trong TONKHO
    IF EXISTS (SELECT i.MaSP FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM TONKHO t WHERE t.MaSP = i.MaSP))
    BEGIN
        RAISERROR(N'Sản phẩm chưa có trong TONKHO – không thể trừ tồn!', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    -- Kiểm tra âm tồn
    IF EXISTS (SELECT 1 FROM inserted i JOIN TONKHO t ON i.MaSP = t.MaSP WHERE t.SoLuongTon < i.SoLuong)
    BEGIN
        RAISERROR(N'Số lượng tồn không đủ để bán – giao dịch bị hủy!', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    -- Cập nhật tồn kho
    UPDATE t SET t.SoLuongTon = t.SoLuongTon - i.SoLuong, t.NgayCapNhat = GETDATE()
    FROM TONKHO t JOIN inserted i ON t.MaSP = i.MaSP;
END
GO

-- 2. trg_BaoVeGia (Chống sốc giá)
CREATE TRIGGER trg_BaoVeGia ON SANPHAM FOR UPDATE
AS
BEGIN
    IF UPDATE(Gia)
    BEGIN
        IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON i.MaSP = d.MaSP WHERE i.Gia < d.Gia * 0.5)
        BEGIN
            RAISERROR(N'Không được giảm giá quá 50% so với giá cũ!',16,1); ROLLBACK TRAN; RETURN;
        END
        INSERT NHATKY_GIA(MaSP, GiaCu, GiaMoi, NgayThayDoi)
        SELECT d.MaSP, d.Gia, i.Gia, GETDATE() FROM inserted i JOIN deleted d ON i.MaSP = d.MaSP
    END
END
GO

-- 3. trg_TongTien_Auto (Tự cập nhật tổng tiền Hóa đơn)
CREATE TRIGGER trg_TongTien_Auto ON CHITIETHOADON AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @MaHD VARCHAR(10);
    SELECT TOP 1 @MaHD=COALESCE(i.MaHD,d.MaHD) FROM inserted i FULL JOIN deleted d ON 1=0;
    UPDATE HOADON SET TongTien=dbo.fn_TongTienHD(@MaHD) WHERE MaHD=@MaHD;
END;
GO

-- 4. trg_ChanBanKhiThieuTon (Kiểm tra tồn trước khi Insert)
CREATE TRIGGER trg_ChanBanKhiThieuTon ON CHITIETHOADON INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted i CROSS APPLY (SELECT dbo.fn_TonKhaDung(i.MaSP) AS TonHienTai) AS T WHERE T.TonHienTai < i.SoLuong)
    BEGIN
        RAISERROR (N'Sản phẩm không đủ tồn kho. Không thể lập hóa đơn.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END;
    INSERT INTO CHITIETHOADON (MaHD, MaSP, SoLuong, DonGia, ThanhTien)
    SELECT MaHD, MaSP, SoLuong, DonGia, ThanhTien FROM inserted;
END;
GO

-- 5. trg_HD_Defaults (Gán giá trị mặc định cho Hóa đơn)
CREATE TRIGGER trg_HD_Defaults ON HOADON INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO HOADON (MaHD, MaNV, MaKH, NgayLap, TongTien, TrangThai, MaKM)
    SELECT MaHD, MaNV, MaKH, ISNULL(NgayLap, GETDATE()), 
           CASE WHEN TongTien IS NULL OR TongTien < 0 THEN 0 ELSE TongTien END,
           ISNULL(TrangThai, N'Chờ duyệt'), MaKM
    FROM INSERTED;
END
GO

-- 6. trg_XuLyKhoTheoTrangThai (Phần của Yến Nhi: Hoàn kho khi Hủy đơn)
CREATE TRIGGER trg_XuLyKhoTheoTrangThai 
ON HOADON
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nếu trạng thái chuyển từ bất kỳ thành 'Đã hủy' -> Cộng lại kho
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.MaHD = d.MaHD 
               WHERE i.TrangThai = N'Đã hủy' AND d.TrangThai <> N'Đã hủy')
    BEGIN
        UPDATE T
        SET T.SoLuongTon = T.SoLuongTon + CT.SoLuong
        FROM TONKHO T
        JOIN CHITIETHOADON CT ON T.MaSP = CT.MaSP
        JOIN inserted i ON CT.MaHD = i.MaHD
        WHERE i.TrangThai = N'Đã hủy';
        
        PRINT N'Đã hoàn kho tự động cho đơn hàng bị hủy.';
    END
END
GO

/* =============================================================
   PHẦN 6: STORED PROCEDURE (THỦ TỤC) & TRANSACTION
   ============================================================= */

-- 1. sp_TaoHoaDon 
CREATE PROCEDURE sp_TaoHoaDon @MaHD VARCHAR(10), @MaNV VARCHAR(10), @MaKH VARCHAR(10)
AS
BEGIN
    BEGIN TRAN;
    INSERT INTO HOADON(MaHD, NgayLap, MaNV, MaKH, TongTien) VALUES(@MaHD, GETDATE(), @MaNV, @MaKH, 0);
    COMMIT;
END;
GO

-- 2. sp_NhapKho 
CREATE PROCEDURE sp_NhapKho @MaSP VARCHAR(10), @SoLuongNhap INT
AS
BEGIN
    IF (@SoLuongNhap <= 0) BEGIN RAISERROR(N'Số lượng nhập phải lớn hơn 0', 16, 1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MaSP = @MaSP) BEGIN RAISERROR(N'Mã sản phẩm không tồn tại', 16, 1); RETURN; END
    
    IF EXISTS (SELECT 1 FROM TONKHO WHERE MaSP = @MaSP)
        UPDATE TONKHO SET SoLuongTon = SoLuongTon + @SoLuongNhap, NgayCapNhat = GETDATE() WHERE MaSP = @MaSP;
    ELSE
        INSERT INTO TONKHO (MaSP, SoLuongTon, NgayCapNhat) VALUES (@MaSP, @SoLuongNhap, GETDATE());
END
GO

-- 3. sp_TimKiemSP 
CREATE PROCEDURE sp_TimKiemSP
    @Ten NVARCHAR(50) = NULL, @MaLoai VARCHAR(10) = NULL, @GiaMin MONEY = NULL, @GiaMax MONEY = NULL
AS
BEGIN
    IF (@GiaMin IS NOT NULL AND @GiaMax IS NOT NULL AND @GiaMin > @GiaMax) BEGIN RAISERROR(N'Khoảng giá không hợp lệ', 16, 1); RETURN; END
    SELECT * FROM SANPHAM WHERE (@Ten IS NULL OR TenSP LIKE '%' + @Ten + '%') AND (@MaLoai IS NULL OR MaLoai = @MaLoai) AND (@GiaMin IS NULL OR Gia >= @GiaMin) AND (@GiaMax IS NULL OR Gia <= @GiaMax);
END
GO

-- 4. sp_TaoKhuyenMai 
CREATE PROC sp_TaoKhuyenMai @MaKM VARCHAR(10), @Ten NVARCHAR(50), @TiLeGiam FLOAT, @NgayBD DATE, @NgayKT DATE
AS
BEGIN
    IF (@TiLeGiam < 0 OR @TiLeGiam > 100) BEGIN RAISERROR (N'Tỉ lệ giảm phải nằm trong khoảng [0,100]', 16, 1); RETURN; END;
    IF (@NgayBD > @NgayKT) BEGIN RAISERROR (N'Ngày bắt đầu không được lớn hơn ngày kết thúc', 16, 1); RETURN; END;
    IF EXISTS (SELECT 1 FROM KHUYENMAI WHERE (@NgayBD <= NgayKT) AND (@NgayKT >= NgayBD)) BEGIN RAISERROR (N'Khoảng thời gian khuyến mãi bị trùng', 16, 1); RETURN; END;
    INSERT INTO KHUYENMAI (MaKM, TenCTKM, TiLeGiam, NgayBD, NgayKT) VALUES (@MaKM, @Ten, @TiLeGiam, @NgayBD, @NgayKT);
END;
GO

-- 5. sp_TopBanChay 
CREATE PROCEDURE sp_TopBanChay @Tu DATE, @Den DATE, @TopN INT = 5
AS
BEGIN
    IF (@Tu > @Den) BEGIN RAISERROR(N'@Tu phải nhỏ hơn hoặc bằng @Den', 16, 1); RETURN; END
    IF (@TopN <= 0) SET @TopN = 5
    SELECT TOP (@TopN) sp.MaSP, sp.TenSP, SUM(ct.SoLuong) AS TongSL
    FROM CHITIETHOADON ct JOIN HOADON hd ON ct.MaHD = hd.MaHD JOIN SANPHAM sp ON ct.MaSP = sp.MaSP
    WHERE hd.NgayLap BETWEEN @Tu AND @Den
    GROUP BY sp.MaSP, sp.TenSP ORDER BY TongSL DESC
END
GO

-- 6. sp_HoanTraHang (Xóa hóa đơn hoàn toàn - Logic cũ, giữ lại tham khảo)
CREATE PROCEDURE sp_HoanTraHang @MaHD VARCHAR(10) 
AS
BEGIN
    SET NOCOUNT ON; BEGIN TRAN
    IF NOT EXISTS(SELECT 1 FROM HOADON WHERE MaHD=@MaHD) BEGIN RAISERROR(N'Hóa đơn không tồn tại!',16,1); ROLLBACK TRAN; RETURN; END
    IF NOT EXISTS(SELECT 1 FROM CHITIETHOADON WHERE MaHD=@MaHD) BEGIN RAISERROR(N'Hóa đơn không có chi tiết!',16,1); ROLLBACK TRAN; RETURN; END
    
    UPDATE T SET T.SoLuongTon = T.SoLuongTon + C.SoLuong
    FROM TONKHO T JOIN CHITIETHOADON C ON T.MaSP = C.MaSP WHERE C.MaHD = @MaHD
    
    DELETE FROM CHITIETHOADON WHERE MaHD=@MaHD
    DELETE FROM HOADON WHERE MaHD=@MaHD
    COMMIT TRAN
END
GO

-- 7. sp_HuyHoaDon (Logic mới của Duyên: Cập nhật trạng thái + Hoàn kho)
CREATE PROCEDURE sp_HuyHoaDon 
    @MaHD VARCHAR(10)
AS
BEGIN
    SET XACT_ABORT ON; 
    BEGIN TRANSACTION;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM HOADON WHERE MaHD = @MaHD)
        BEGIN
            RAISERROR(N'Hóa đơn không tồn tại!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Hoàn kho (Dù đã có Trigger nhưng Procedure này chủ động xử lý để đảm bảo atomic)
        UPDATE T
        SET T.SoLuongTon = T.SoLuongTon + CT.SoLuong,
            T.NgayCapNhat = GETDATE()
        FROM TONKHO T
        INNER JOIN CHITIETHOADON CT ON T.MaSP = CT.MaSP
        WHERE CT.MaHD = @MaHD;

        -- Cập nhật trạng thái
        UPDATE HOADON
        SET TrangThai = N'Đã hủy'
        WHERE MaHD = @MaHD;

        COMMIT TRANSACTION;
        PRINT N'Đã hủy đơn hàng và hoàn kho thành công cho mã: ' + @MaHD;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 8. sp_GopHoaDon 
CREATE PROCEDURE sp_GopHoaDon @MaKH VARCHAR(10), @Ngay DATE
AS
BEGIN
    BEGIN TRY BEGIN TRAN;
        DECLARE @tblHD TABLE (MaHD VARCHAR(10));
        INSERT INTO @tblHD(MaHD) SELECT MaHD FROM HOADON WHERE MaKH = @MaKH AND NgayLap = @Ngay;
        IF NOT EXISTS (SELECT 1 FROM @tblHD) BEGIN RAISERROR(N'Không có hóa đơn để gộp', 16, 1); ROLLBACK TRAN; RETURN; END
        
        DECLARE @MaHDGoc VARCHAR(10) = (SELECT TOP 1 MaHD FROM @tblHD ORDER BY MaHD);
        UPDATE CHITIETHOADON SET MaHD = @MaHDGoc WHERE MaHD IN (SELECT MaHD FROM @tblHD WHERE MaHD <> @MaHDGoc);
        DELETE FROM HOADON WHERE MaHD IN (SELECT MaHD FROM @tblHD WHERE MaHD <> @MaHDGoc);
        
        DECLARE @TongTien MONEY;
        SELECT @TongTien = SUM(ThanhTien) FROM CHITIETHOADON WHERE MaHD = @MaHDGoc;
        UPDATE HOADON SET TongTien = ISNULL(@TongTien, 0) WHERE MaHD = @MaHDGoc;
    COMMIT TRAN; END TRY
    BEGIN CATCH ROLLBACK TRAN; PRINT N'Lỗi hóa đơn'; END CATCH
END
GO

-- 9. sp_TraHangTungPhan 
CREATE PROCEDURE sp_TraHangTungPhan @MaHD VARCHAR(10), @MaSP VARCHAR(10), @SLTra INT
AS
BEGIN
    DECLARE @SoLuongDaMua INT, @DonGia DECIMAL(18, 0), @GiaTriTra DECIMAL(18, 0);
    BEGIN TRAN;
    SELECT @SoLuongDaMua = SoLuong, @DonGia = DonGia FROM CHITIETHOADON WHERE MaHD = @MaHD AND MaSP = @MaSP;
    IF @SoLuongDaMua IS NULL BEGIN RAISERROR (N'Không tìm thấy sản phẩm', 16, 1); ROLLBACK TRAN; RETURN; END;
    IF @SLTra > @SoLuongDaMua BEGIN RAISERROR (N'Số lượng trả quá số lượng mua', 16, 1); ROLLBACK TRAN; RETURN; END;
    
    SET @GiaTriTra = @SLTra * @DonGia;
    UPDATE CHITIETHOADON SET SoLuong = SoLuong - @SLTra, ThanhTien = (@SoLuongDaMua - @SLTra) * @DonGia WHERE MaHD = @MaHD AND MaSP = @MaSP;
    UPDATE TONKHO SET SoLuongTon = SoLuongTon + @SLTra, NgayCapNhat = GETDATE() WHERE MaSP = @MaSP;
    UPDATE HOADON SET TongTien = TongTien - @GiaTriTra WHERE MaHD = @MaHD;
    COMMIT TRAN;
END;
GO

-- 10. sp_OnboardKH 
CREATE PROCEDURE sp_OnboardKH @MaKH VARCHAR(10), @DiaChiMoi NVARCHAR(100), @MaNV VARCHAR(10)
AS
BEGIN
    BEGIN TRY BEGIN TRAN;
        IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MaKH = @MaKH) BEGIN RAISERROR(N'Mã khách hàng không tồn tại!', 16, 1); ROLLBACK TRAN; RETURN; END
        UPDATE KHACHHANG SET DiaChi = @DiaChiMoi WHERE MaKH = @MaKH;
        
        DECLARE @MaHD VARCHAR(10) = 'HD' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR(4)), 4);
        INSERT INTO HOADON (MaHD, MaKH, MaNV, NgayLap, TongTien) VALUES (@MaHD, @MaKH, @MaNV, GETDATE(), 0);
    COMMIT TRAN; END TRY
    BEGIN CATCH ROLLBACK TRAN; PRINT N'Lỗi sp_OnboardKH'; END CATCH
END
GO

-- 11. sp_SanPhamSapHetHang 
CREATE PROCEDURE sp_SanPhamSapHetHang @Nguong INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaSP, SoLuongTon FROM TONKHO WHERE SoLuongTon < @Nguong;
END
GO

/* =============================================================
   PHẦN 7: BẢO MẬT & PHÂN QUYỀN
   ============================================================= */

-- Tạo Roles
CREATE ROLE Role_BanHang;
CREATE ROLE Role_QuanLyKho;
CREATE ROLE Role_GiamDoc;
GO

-- Phân quyền cho Nhóm Bán Hàng
GRANT SELECT ON SANPHAM TO Role_BanHang;
GRANT SELECT ON KHACHHANG TO Role_BanHang;
GRANT SELECT ON KHUYENMAI TO Role_BanHang;
GRANT EXECUTE ON sp_TimKiemSP TO Role_BanHang;
GRANT EXECUTE ON sp_TaoHoaDon TO Role_BanHang;
GRANT EXECUTE ON fn_TongTienHD TO Role_BanHang;
GRANT EXECUTE ON sp_OnboardKH TO Role_BanHang;

-- Phân quyền cho Nhóm Kho
GRANT SELECT, UPDATE ON TONKHO TO Role_QuanLyKho;
GRANT EXECUTE ON sp_NhapKho TO Role_QuanLyKho;
GRANT EXECUTE ON sp_SanPhamSapHetHang TO Role_QuanLyKho;

-- Phân quyền cho Giám Đốc
ALTER ROLE db_owner ADD MEMBER Role_GiamDoc;
GO

/* =============================================================
   PHẦN 8: KỊCH BẢN DEMO SAO LƯU VÀ KHÔI PHỤC
   ============================================================= */
-- (Phần này để chạy thủ công khi cần Demo, không chạy tự động khi execute script)

/*
USE master;
GO
ALTER DATABASE QL_MyPham_Cocoon SET RECOVERY FULL;
GO
USE QL_MyPham_Cocoon;
GO

-- FULL BACKUP
BACKUP DATABASE QL_MyPham_Cocoon TO DISK = 'C:\Backup\Cocoon_Full_t1.bak' WITH FORMAT, INIT, NAME = N'Cocoon Full Backup t1';
GO

-- LOG BACKUP
BACKUP LOG QL_MyPham_Cocoon TO DISK = 'C:\Backup\Cocoon_Log_t2.trn' WITH INIT, NAME = N'Cocoon Log Backup t2';
GO

-- DIFF BACKUP
BACKUP DATABASE QL_MyPham_Cocoon TO DISK = 'C:\Backup\Cocoon_Diff_t4.bak' WITH DIFFERENTIAL, INIT, NAME = N'Cocoon Diff Backup t4';
GO

-- TAIL LOG BACKUP
BACKUP LOG QL_MyPham_Cocoon TO DISK = 'C:\Backup\Cocoon_Log_t5.trn' WITH INIT, NAME = N'Cocoon Log Backup t5';
GO
*/


-- Cập nhật cột SoLuong trong bảng SANPHAM 
-- sao cho bằng đúng với cột SoLuongTon trong bảng TONKHO
UPDATE SANPHAM
SET SoLuong = T.SoLuongTon
FROM SANPHAM S
INNER JOIN TONKHO T ON S.MaSP = T.MaSP;

-- Tự động thêm vào bảng TONKHO những sản phẩm nào có bên SANPHAM mà đang bị thiếu bên TONKHO
INSERT INTO TONKHO (MaSP, SoLuongTon, NgayCapNhat)
SELECT MaSP, SoLuong, GETDATE()
FROM SANPHAM
WHERE MaSP NOT IN (SELECT MaSP FROM TONKHO);

-- 1. Thêm cột GiaVon vào bảng SANPHAM
ALTER TABLE SANPHAM
ADD GiaVon MONEY DEFAULT 0;
GO

-- 2. Cập nhật dữ liệu giả định (Để tránh báo cáo bị lỗ hoặc lợi nhuận 100%)
-- Giả sử Giá vốn = 60% Giá bán
UPDATE SANPHAM
SET GiaVon = Gia * 0.6;
GO


use QL_MyPham_Cocoon
ALTER TABLE NHANVIEN
ADD TrangThai BIT DEFAULT 1 WITH VALUES;
GO
SELECT * FROM NHANVIEN