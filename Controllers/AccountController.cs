using Nhom5_Mypham.Helpers;
using Nhom5_Mypham.Models;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Web.Mvc;

namespace Nhom5_Mypham.Controllers
{
    public class AccountController : Controller
    {
        private QL_MyPham_CocoonEntities db = new QL_MyPham_CocoonEntities();

        // ------------------- ĐĂNG NHẬP -------------------
        [HttpGet]
        public ActionResult Login()
        {
            Session["KH"] = null;
            return View();
        }

        [HttpPost]
        public ActionResult Login(string email, string matkhau)
        {
            // KIỂM TRA CAPTCHA
            if (!IsCaptchaValid())
            {
                ViewBag.Error = "Vui lòng xác thực bạn không phải là người máy!";
                return View();
            }

            // KIỂM TRA INPUT
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(matkhau))
            {
                ViewBag.Error = "Vui lòng nhập đầy đủ thông tin (Email và Mật khẩu)!";
                return View();
            }

            string emailTrim = email.Trim().ToLower();
            string mkMaHoa = SecurityHelper.GetMD5(matkhau.Trim()).ToUpper();

            // TÌM KHÁCH HÀNG
            var khachHang = db.KHACHHANGs.FirstOrDefault(s =>
                s.Email.Trim().ToLower() == emailTrim &&
                s.MatKhau.Trim().ToUpper() == mkMaHoa);

            if (khachHang != null)
            {
                Session["KH"] = khachHang;
                return RedirectToAction("Index", "Home");
            }

            ViewBag.Error = "Email hoặc mật khẩu không chính xác!";
            return View();
        }

        // ------------------- ĐĂNG KÝ -------------------
        [HttpGet]
        public ActionResult Register()
        {
            return View(new KHACHHANG());
        }

        [HttpPost]
        public ActionResult Register(KHACHHANG kh)
        {
            // KIỂM TRA CAPTCHA
            if (!IsCaptchaValid())
            {
                ViewBag.Error = "Vui lòng xác nhận bạn không phải là người máy!";
                return View(kh);
            }

            // KIỂM TRA LOGIC ĐĂNG KÝ
            if (ModelState.IsValid)
            {
                if (kh.SDT.Length != 10 || !kh.SDT.All(char.IsDigit))
                {
                    ViewBag.Error = "Số điện thoại phải đủ 10 số!";
                    return View(kh);
                }

                if (db.KHACHHANGs.Any(x => x.SDT == kh.SDT))
                {
                    ViewBag.Error = "Số điện thoại này đã được sử dụng!";
                    return View(kh);
                }

                var checkEmail = db.KHACHHANGs.FirstOrDefault(s => s.Email.Trim().ToLower() == kh.Email.Trim().ToLower());
                if (checkEmail == null)
                {
                    kh.MaKH = "KH" + Guid.NewGuid().ToString().Substring(0, 5).ToUpper();

                    if (!string.IsNullOrEmpty(kh.MatKhau))
                    {
                        kh.MatKhau = SecurityHelper.GetMD5(kh.MatKhau.Trim()).ToUpper();
                    }

                    db.KHACHHANGs.Add(kh);
                    db.SaveChanges();

                    TempData["Success"] = "Đăng ký thành công! Mời bạn đăng nhập.";
                    return RedirectToAction("Login");
                }
                else
                {
                    ViewBag.Error = "Email này đã được sử dụng!";
                    return View(kh);
                }
            }
            return View(kh);
        }

        // ------------------- ĐĂNG XUẤT -------------------
        public ActionResult Logout()
        {
            Session["KH"] = null;
            return RedirectToAction("Login");
        }

        // ------------------- LỊCH SỬ --------------------
        public ActionResult History()
        {
            if (Session["KH"] == null) return RedirectToAction("Login");

            var kh = Session["KH"] as KHACHHANG;

            var list = db.HOADONs
                .Where(x => x.MaKH == kh.MaKH)
                .OrderByDescending(x => x.NgayLap)
                .ToList();

            return View(list);
        }

        // ------------------- CHI TIẾT TK ----------------
        [HttpGet]
        public ActionResult Details()
        {
            if (Session["KH"] == null) return RedirectToAction("Login", "Account");

            var khachHangSession = Session["KH"] as KHACHHANG;

            KHACHHANG khachHang = db.KHACHHANGs.Find(khachHangSession.MaKH);

            if (khachHang == null)
            {
                Session.Remove("KH");
                return RedirectToAction("Login");
            }
            return View(khachHang);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Details(KHACHHANG model)
        {
            if (Session["KH"] == null) return RedirectToAction("Login", "Account");

            if (ModelState.IsValid)
            {
                var currentKhachHang = db.KHACHHANGs.Find(model.MaKH);
                if (currentKhachHang != null)
                {
                    currentKhachHang.HoTen = model.HoTen;
                    currentKhachHang.NgaySinh = model.NgaySinh;
                    currentKhachHang.GioiTinh = model.GioiTinh;
                    currentKhachHang.Email = model.Email;
                    currentKhachHang.DiaChi = model.DiaChi;

                    db.Entry(currentKhachHang).State = EntityState.Modified;
                    db.SaveChanges();

                    Session["KH"] = currentKhachHang;

                    ViewBag.SuccessMessage = "Cập nhật thông tin thành công!";
                    return View(currentKhachHang);
                }
            }
            return View(model);
        }

        // ------------------- CANCEL ORDER ---------------
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CancelOrder(string id)
        {
            if (Session["KH"] == null) return RedirectToAction("Login");

            var kh = Session["KH"] as KHACHHANG;

            var hd = db.HOADONs.FirstOrDefault(x => x.MaHD == id && x.MaKH == kh.MaKH);

            if (hd != null)
            {
                if (hd.TrangThai == "Chờ duyệt")
                {
                    try
                    {
                        db.Database.ExecuteSqlCommand("EXEC sp_HuyHoaDon @MaHD", new System.Data.SqlClient.SqlParameter("@MaHD", id));

                        TempData["Success"] = "Hủy đơn hàng " + id + " thành công. Sản phẩm đã được hoàn lại kho.";
                    }
                    catch (Exception ex)
                    {
                        TempData["Error"] = "Lỗi khi hủy đơn: " + ex.Message;
                    }
                }
                else
                {
                    TempData["Error"] = "Đơn hàng đã được xử lý hoặc vận chuyển, không thể hủy!";
                }
            }

            return RedirectToAction("History");
        }

        // ------------------- HELPERS --------------------
        private bool IsCaptchaValid()
        {
            var response = Request["g-recaptcha-response"];
            const string secret = "6LegdjAsAAAAAKozzTDRYX19DCaUya_t6ZZnTYf7";

            if (string.IsNullOrEmpty(response)) return false;

            try
            {
                using (var client = new System.Net.WebClient())
                {
                    var result = client.DownloadString(
                        $"https://www.google.com/recaptcha/api/siteverify?secret={secret}&response={response}"
                    );
                    return result.ToLower().Contains("\"success\": true");
                }
            }
            catch
            {
                return false;
            }
        }
    }
}