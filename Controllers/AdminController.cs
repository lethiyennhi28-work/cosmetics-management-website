using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient; 
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using OfficeOpenXml; 
using Nhom5_Mypham.Models;
using Nhom5_Mypham.Helpers;

public class AdminController : Controller
{
    private QL_MyPham_CocoonEntities db = new QL_MyPham_CocoonEntities();

    // ĐĂNG NHẬP & ĐĂNG XUẤT
    [HttpGet]
    public ActionResult Login() { return View(); }

    [HttpPost]
    public ActionResult Login(string username, string password)
    {
        string passwordMaHoa = SecurityHelper.GetMD5(password);

        var nhanVien = db.NHANVIENs.FirstOrDefault(x => x.Username == username && x.Password == passwordMaHoa);

        if (nhanVien != null)
        {
            if (nhanVien.TrangThai == false)
            {
                ViewBag.Error = "⛔ Tài khoản này đã bị KHÓA! Vui lòng liên hệ Giám đốc để mở lại.";
                return View();
            }

            Session["Admin"] = nhanVien;
            Session["HoTen"] = nhanVien.HoTen;
            Session["ChucVu"] = nhanVien.ChucVu;

            // Phân quyền chuyển hướng
            if (nhanVien.ChucVu == "Giám đốc" || nhanVien.ChucVu == "Kế toán")
            {
                return RedirectToAction("Dashboard");
            }

            return RedirectToAction("Index");
        }

        ViewBag.Error = "Sai tài khoản hoặc mật khẩu!";
        return View();
    }

    public ActionResult Logout()
    {
        Session.Clear();
        return RedirectToAction("Login");
    }

    // 2. DASHBOARD - BÁO CÁO
    public ActionResult Dashboard()
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        // Chỉ Giám đốc và kế toán được xem
        string role = Session["ChucVu"] as string;
        if (role != "Giám đốc" && role != "Kế toán")
        {
            return RedirectToAction("Index");
        }

        // Doanh thu & Sản phẩm 
        decimal doanhThu = db.HOADONs.AsNoTracking().Sum(x => (decimal?)x.TongTien) ?? 0;
        int soSp = db.SANPHAMs.AsNoTracking().Count();
        int soKh = db.KHACHHANGs.AsNoTracking().Count();

        // Số liệu Nhân sự & Lương 
        int soNv = db.NHANVIENs.AsNoTracking().Count();
        decimal tongLuong = db.NHANVIENs.AsNoTracking().Sum(x => (decimal?)x.Luong) ?? 0;

        ViewBag.TongDoanhThu = doanhThu;
        ViewBag.SoSanPham = soSp;
        ViewBag.SoKhachHang = soKh;
        ViewBag.SoNhanVien = soNv;
        ViewBag.TongLuong = tongLuong;

        return View();
    }

    // QUẢN LÝ SẢN PHẨM & KHO

    public ActionResult Index(string search, string loaiDa, decimal? giaTu)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var q = db.SANPHAMs.AsQueryable();

        // Lọc theo từ khóa tìm kiếm
        if (!string.IsNullOrEmpty(search))
            q = q.Where(x => x.TenSP.Contains(search));

        // Lọc theo Loại da
        if (!string.IsNullOrEmpty(loaiDa))
        {
            q = q.Where(x => x.LoaiDa == loaiDa);
        }

        // Lọc theo giá bán từ
        if (giaTu.HasValue)
        {
            q = q.Where(x => x.Gia >= giaTu.Value);
        }

        return View(q.ToList());
    }

    public ActionResult Create()
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string role = Session["ChucVu"] as string;

        if (role != "Trưởng phòng" && role != "Phó phòng")
        {
            TempData["Error"] = "⛔ Bạn không có quyền Thêm sản phẩm.";
            return RedirectToAction("Index");
        }

        ViewBag.MaLoai = new SelectList(db.LOAISANPHAMs, "MaLoai", "TenLoai");
        ViewBag.MaNCC = new SelectList(db.NHACUNGCAPs, "MaNCC", "TenNCC");
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult Create(SANPHAM sp, HttpPostedFileBase upload)
    {
        if (ModelState.IsValid)
        {
            if (upload != null && upload.ContentLength > 0)
            {
                string _FileName = Path.GetFileName(upload.FileName);
                string _path = Server.MapPath("~/Images/" + _FileName);
                upload.SaveAs(_path);
                sp.HinhAnh = _FileName;
            }

            db.SANPHAMs.Add(sp);

            var kho = new TONKHO();
            kho.MaSP = sp.MaSP;
            kho.SoLuongTon = sp.SoLuong;
            kho.NgayCapNhat = DateTime.Now;
            db.TONKHOes.Add(kho);

            db.SaveChanges();
            return RedirectToAction("Index");
        }

        ViewBag.MaLoai = new SelectList(db.LOAISANPHAMs, "MaLoai", "TenLoai", sp.MaLoai);
        ViewBag.MaNCC = new SelectList(db.NHACUNGCAPs, "MaNCC", "TenNCC", sp.MaNCC);
        return View(sp);
    }

    public ActionResult Edit(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string role = Session["ChucVu"] as string;

        if (role != "Trưởng phòng")
        {
            TempData["Error"] = "⛔ Chỉ Trưởng phòng mới được quyền Sửa sản phẩm.";
            return RedirectToAction("Index");
        }

        if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
        SANPHAM sp = db.SANPHAMs.Find(id);
        if (sp == null) return HttpNotFound();

        ViewBag.MaLoai = new SelectList(db.LOAISANPHAMs, "MaLoai", "TenLoai", sp.MaLoai);
        ViewBag.MaNCC = new SelectList(db.NHACUNGCAPs, "MaNCC", "TenNCC", sp.MaNCC);
        return View(sp);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult Edit(SANPHAM model, HttpPostedFileBase upload)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string role = Session["ChucVu"] as string;
        if (role != "Trưởng phòng" && role != "Phó phòng")
        {
            TempData["Error"] = "Bạn không có quyền sửa thông tin này.";
            return RedirectToAction("Index");
        }

        if (ModelState.IsValid)
        {
            try
            {
                var spGoc = db.SANPHAMs.Find(model.MaSP);
                if (spGoc == null) return HttpNotFound();

                spGoc.TenSP = model.TenSP;
                spGoc.Gia = model.Gia;
                spGoc.MaLoai = model.MaLoai;
                spGoc.MaNCC = model.MaNCC;
                spGoc.HanSD = model.HanSD;

                if (upload != null && upload.ContentLength > 0)
                {
                    string _FileName = Path.GetFileName(upload.FileName);
                    string _path = Server.MapPath("~/Images/" + _FileName);
                    upload.SaveAs(_path);
                    spGoc.HinhAnh = _FileName;
                }

                if (model.SoLuong != spGoc.SoLuong)
                {
                    spGoc.SoLuong = model.SoLuong;
                    var tonKho = db.TONKHOes.FirstOrDefault(x => x.MaSP == model.MaSP);
                    if (tonKho != null)
                    {
                        tonKho.SoLuongTon = model.SoLuong;
                        tonKho.NgayCapNhat = DateTime.Now;
                    }
                    else
                    {
                        db.TONKHOes.Add(new TONKHO
                        {
                            MaSP = model.MaSP,
                            SoLuongTon = model.SoLuong,
                            NgayCapNhat = DateTime.Now
                        });
                    }
                }

                db.Entry(spGoc).State = EntityState.Modified;
                db.SaveChanges();

                TempData["Success"] = "Cập nhật sản phẩm và đồng bộ kho thành công!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Lỗi cập nhật: " + ex.Message;
            }
        }

        ViewBag.MaLoai = new SelectList(db.LOAISANPHAMs, "MaLoai", "TenLoai", model.MaLoai);
        ViewBag.MaNCC = new SelectList(db.NHACUNGCAPs, "MaNCC", "TenNCC", model.MaNCC);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult DeleteConfirmed(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        string role = Session["ChucVu"] as string;
        if (role != "Trưởng phòng")
        {
            TempData["Error"] = "⛔ Chỉ Trưởng phòng mới được quyền Xóa.";
            return RedirectToAction("Index");
        }

        var sp = db.SANPHAMs.Find(id);
        if (sp != null)
        {
            var tonKho = db.TONKHOes.FirstOrDefault(x => x.MaSP == id);
            if (tonKho != null) db.TONKHOes.Remove(tonKho);

            db.SANPHAMs.Remove(sp);
            db.SaveChanges();
            TempData["Success"] = "Đã xóa sản phẩm!";
        }
        return RedirectToAction("Index");
    }

    // NHẬP HÀNG & TÍNH GIÁ VỐN
    [HttpGet]
    public ActionResult NhapHang(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        var sp = db.SANPHAMs.Find(id);
        return View(sp);
    }

    [HttpPost]
    public ActionResult NhapHang(string id, int soLuongNhap, decimal giaNhap)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var sp = db.SANPHAMs.Find(id);
        if (sp != null)
        {
            decimal tongVonCu = (decimal)((sp.SoLuong ?? 0) * (sp.GiaVon ?? 0));
            decimal tongVonMoi = (decimal)(soLuongNhap * giaNhap);
            int tongSoLuong = (sp.SoLuong ?? 0) + soLuongNhap;

            if (tongSoLuong > 0)
                sp.GiaVon = (tongVonCu + tongVonMoi) / tongSoLuong;
            else
                sp.GiaVon = giaNhap;

            sp.SoLuong = tongSoLuong;

            var tonKho = db.TONKHOes.FirstOrDefault(x => x.MaSP == id);
            if (tonKho != null)
            {
                tonKho.SoLuongTon = tongSoLuong;
                tonKho.NgayCapNhat = DateTime.Now;
            }
            else
            {
                var newKho = new TONKHO { MaSP = id, SoLuongTon = soLuongNhap, NgayCapNhat = DateTime.Now };
                db.TONKHOes.Add(newKho);
            }

            db.SaveChanges();
            TempData["Success"] = "Nhập kho thành công!";
        }
        return RedirectToAction("Index");
    }

    // BÁO CÁO LỢI NHUẬN
    [HttpGet]
    public ActionResult BaoCaoLoiNhuan(DateTime? tuNgay, DateTime? denNgay)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string role = Session["ChucVu"] as string;

        if (role != "Kế toán" && role != "Giám đốc")
        {
            TempData["Error"] = "Bạn không có quyền truy cập báo cáo lợi nhuận!";
            return RedirectToAction("Index");
        }

        if (tuNgay == null) tuNgay = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
        if (denNgay == null) denNgay = DateTime.Now;

        ViewBag.TuNgay = tuNgay;
        ViewBag.DenNgay = denNgay;

        var listDonHang = db.HOADONs
            .Where(x => (x.TrangThai == "Hoàn tất" || x.TrangThai == "2" || x.TrangThai == "Đã giao")
                     && x.NgayLap >= tuNgay && x.NgayLap <= denNgay)
            .ToList();

        decimal tongDoanhThu = 0;
        decimal tongGiaVon = 0;

        foreach (var hd in listDonHang)
        {
            tongDoanhThu += (hd.TongTien ?? 0);
            foreach (var ct in hd.CHITIETHOADONs)
            {
                decimal vonCuaSP = (ct.SANPHAM.GiaVon ?? 0) * (ct.SoLuong ?? 0);
                tongGiaVon += vonCuaSP;
            }
        }

        ViewBag.DoanhThu = tongDoanhThu;
        ViewBag.TongVon = tongGiaVon;
        ViewBag.LoiNhuan = tongDoanhThu - tongGiaVon;

        return View();
    }

    // QUẢN LÝ ĐƠN HÀNG

    public ActionResult OrderList()
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        string role = Session["ChucVu"] as string;
        if (role != "Giám đốc" && role != "Kế toán")
        {
            TempData["Error"] = "⛔ Bạn không có quyền xem danh sách đơn hàng.";
            return RedirectToAction("Index");
        }

        var orders = db.HOADONs.OrderByDescending(x => x.NgayLap).ToList();
        return View(orders);
    }

    public ActionResult Order_status(string statusFilter, string loaiDa, decimal? giaTu)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var orders = db.HOADONs
                        .Include(h => h.KHACHHANG)
                        .Include("CHITIETHOADONs.SANPHAM")
                        .AsQueryable();

        if (!string.IsNullOrEmpty(statusFilter))
        {
            orders = orders.Where(x => x.TrangThai == statusFilter);
        }

        if (!string.IsNullOrEmpty(loaiDa))
        {
            orders = orders.Where(x => x.CHITIETHOADONs.Any(ct => ct.SANPHAM.LoaiDa == loaiDa));
        }

        if (giaTu.HasValue)
        {
            orders = orders.Where(x => x.TongTien >= giaTu.Value);
        }

        var result = orders.OrderByDescending(x => x.NgayLap).ToList();
        ViewBag.CurrentFilter = statusFilter;
        return View(result);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult Order_status(string id, string newStatus)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var hd = db.HOADONs.Find(id);
        if (hd != null)
        {
            try
            {
                if (newStatus == "Đã hủy" || newStatus == "-1")
                {
                    db.Database.ExecuteSqlCommand("EXEC sp_HuyHoaDon @MaHD", new SqlParameter("@MaHD", id));
                    hd.TrangThai = "Đã hủy";
                }
                else
                {
                    hd.TrangThai = newStatus;
                }

                db.SaveChanges();
                TempData["Success"] = "Đã cập nhật đơn hàng " + id + " sang trạng thái: " + newStatus;
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi: " + ex.Message;
            }
        }
        return RedirectToAction("Order_status");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult ApproveOrder(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var nv = Session["Admin"] as NHANVIEN; 
        var hd = db.HOADONs.Find(id);

        if (hd != null && nv != null)
        {
            hd.TrangThai = "Đang giao";
            hd.MaNV = nv.MaNV;

            db.SaveChanges();
            TempData["Success"] = "Đã duyệt đơn hàng " + id + " bởi nhân viên: " + nv.HoTen;
        }
        return RedirectToAction("OrderList");
    }

    public ActionResult PrintInvoice(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        var hd = db.HOADONs
                    .Include("KHACHHANG")
                    .Include("NHANVIEN") 
                    .Include("CHITIETHOADONs.SANPHAM")
                    .FirstOrDefault(x => x.MaHD == id);

        if (hd == null) return HttpNotFound();

        if (hd.TrangThai == "Đã hủy" || hd.TrangThai == "-1")
        {
            TempData["Error"] = "Đơn hàng này đã bị hủy, không thể in hóa đơn!";
            return RedirectToAction("Order_status");
        }

        return View(hd);
    }

    // QUẢN LÝ KHÁCH HÀNG
    public ActionResult CustomerList()
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        string role = Session["ChucVu"] as string;
        if (role == "Kế toán")
        {
            TempData["Error"] = "⛔ Kế toán không cần xem danh sách Khách hàng!";
            return RedirectToAction("Index");
        }

        return View(db.KHACHHANGs.ToList());
    }

    // QUẢN LÝ NHÂN SỰ & PHÂN QUYỀN

    public ActionResult EmployeeList()
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");

        string myRole = Session["ChucVu"] as string;
        IQueryable<NHANVIEN> query = db.NHANVIENs;

        if (myRole == "Giám đốc") { }
        else if (myRole == "Kế toán")
        {
            query = query.Where(x => x.ChucVu != "Giám đốc" && x.ChucVu != "Kế toán");
        }
        else if (myRole == "Trưởng phòng")
        {
            query = query.Where(x => x.ChucVu == "Phó phòng" || x.ChucVu == "Nhân viên");
        }
        else if (myRole == "Phó phòng")
        {
            query = query.Where(x => x.ChucVu == "Nhân viên");
        }
        else
        {
            TempData["Error"] = "⛔ Bạn không có quyền truy cập mục này.";
            return RedirectToAction("Index");
        }

        return View(query.ToList());
    }

    [HttpPost]
    public ActionResult CreateEmployee(NHANVIEN nv)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string myRole = Session["ChucVu"] as string;
        if (myRole != "Giám đốc")
        {
            TempData["Error"] = "⛔ Chỉ Giám đốc mới được thêm nhân viên.";
            return RedirectToAction("EmployeeList");
        }

        if (ModelState.IsValid)
        {
            bool isDuplicateId = db.NHANVIENs.Any(x => x.MaNV == nv.MaNV);
            if (isDuplicateId)
            {
                ModelState.AddModelError("MaNV", "Mã nhân viên này đã tồn tại! Vui lòng chọn mã khác.");
                return View(nv);
            }

            bool isDuplicateUser = db.NHANVIENs.Any(x => x.Username == nv.Username);
            if (isDuplicateUser)
            {
                ModelState.AddModelError("Username", "Tên đăng nhập này đã được sử dụng!");
                return View(nv);
            }

            try
            {
                nv.Password = SecurityHelper.GetMD5(nv.Password);
                db.NHANVIENs.Add(nv);
                db.SaveChanges();

                TempData["Success"] = "Thêm nhân viên " + nv.HoTen + " thành công!";
                return RedirectToAction("EmployeeList");
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Có lỗi xảy ra khi lưu: " + ex.Message;
                return View(nv);
            }
        }
        return View(nv);
    }

    public ActionResult EditRole(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string myRole = Session["ChucVu"] as string;

        if (myRole != "Giám đốc")
        {
            TempData["Error"] = "⛔ Bạn không có quyền chỉnh sửa nhân viên này.";
            return RedirectToAction("EmployeeList");
        }

        if (id == null) return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
        var nv = db.NHANVIENs.Find(id);
        if (nv == null) return HttpNotFound();

        ViewBag.ChucVuList = new List<string> { "Giám đốc", "Kế toán", "Trưởng phòng", "Phó phòng", "Nhân viên" };
        return View(nv);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public ActionResult EditRole(NHANVIEN nv)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string myRole = Session["ChucVu"] as string;

        if (myRole != "Giám đốc")
        {
            TempData["Error"] = "⛔ Bạn không có quyền chỉnh sửa thông tin.";
            return RedirectToAction("EmployeeList");
        }

        if (ModelState.IsValid)
        {
            var existingNV = db.NHANVIENs.Find(nv.MaNV);
            if (existingNV != null)
            {
                existingNV.ChucVu = nv.ChucVu;
                db.SaveChanges();
                return RedirectToAction("EmployeeList");
            }
        }
        return View(nv);
    }

    public ActionResult LockAccount(string id)
    {
        if (Session["Admin"] == null) return RedirectToAction("Login");
        string myRole = Session["ChucVu"] as string;
        if (myRole != "Giám đốc")
        {
            TempData["Error"] = "⛔ Bạn không có quyền khóa/mở khóa tài khoản.";
            return RedirectToAction("EmployeeList");
        }

        var nv = db.NHANVIENs.Find(id);

        if (nv != null)
        {
            var adminDangNhap = Session["Admin"] as NHANVIEN;
            if (adminDangNhap != null && adminDangNhap.MaNV == id)
            {
                TempData["Error"] = "Bạn không thể tự khóa tài khoản của chính mình!";
                return RedirectToAction("EmployeeList");
            }

            bool trangThaiHienTai = nv.TrangThai ?? true;
            nv.TrangThai = !trangThaiHienTai;
            db.SaveChanges();

            string msg = (nv.TrangThai == true) ? "Đã mở khóa" : "Đã khóa";
            TempData["Success"] = $"{msg} tài khoản {nv.Username} thành công!";
        }
        else
        {
            TempData["Error"] = "Không tìm thấy nhân viên này!";
        }

        return RedirectToAction("EmployeeList");
    }
}