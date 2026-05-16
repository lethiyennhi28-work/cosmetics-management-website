using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Nhom5_Mypham.Models;
using System.Data.Entity.Infrastructure;

namespace Nhom5_Mypham.Controllers
{
    public class CartController : Controller
    {
        private QL_MyPham_CocoonEntities db = new QL_MyPham_CocoonEntities();

        // XEM GIỎ HÀNG
        public ActionResult Index()
        {
            var cart = Session["Cart"] as List<CartItem> ?? new List<CartItem>();
            ViewBag.TongTien = cart.Sum(item => item.ThanhTien);
            ViewBag.MaPT = new SelectList(db.PHUONGTHUCTHANHTOANs, "MaPT", "TenPT");
            return View(cart);
        }

        // 2. THÊM VÀO GIỎ
        [HttpPost]
        public ActionResult AddToCartAjax(string maSP, int quantity = 1)
        {
            if (Session["KH"] == null) return Json(new { success = false, requireLogin = true });

            var product = db.SANPHAMs.Find(maSP);
            if (product != null)
            {
                var cart = Session["Cart"] as List<CartItem> ?? new List<CartItem>();
                var item = cart.FirstOrDefault(x => x.MaSP == maSP);

                if (item != null) item.SoLuong += quantity;
                else
                {
                    string img = product.HinhAnh ?? "poster.jpg";
                    cart.Add(new CartItem
                    {
                        MaSP = product.MaSP,
                        TenSP = product.TenSP,
                        Gia = (decimal)product.Gia,
                        SoLuong = quantity,
                        HinhAnh = img
                    });
                }
                Session["Cart"] = cart;
                return Json(new { success = true, count = cart.Count });
            }
            return Json(new { success = false });
        }

        // CẬP NHẬT GIỎ HÀNG
        [HttpPost]
        public ActionResult UpdateCart(string maSP, int quantity)
        {
            var cart = Session["Cart"] as List<CartItem>;
            if (cart != null)
            {
                var item = cart.FirstOrDefault(x => x.MaSP == maSP);
                if (item != null)
                {
                    item.SoLuong = quantity;
                    if (item.SoLuong <= 0) cart.Remove(item);
                }
                Session["Cart"] = cart;
                return Json(new { success = true, newTotal = item != null ? item.ThanhTien : 0, cartTotal = cart.Sum(x => x.ThanhTien) });
            }
            return Json(new { success = false });
        }

        // XÓA SẢN PHẨM KHỎI GIỎ
        public ActionResult RemoveFromCart(string maSP)
        {
            var cart = Session["Cart"] as List<CartItem>;
            if (cart != null)
            {
                var item = cart.FirstOrDefault(x => x.MaSP == maSP);
                if (item != null)
                {
                    cart.Remove(item);
                    Session["Cart"] = cart;
                }
            }
            return RedirectToAction("Index");
        }

        // ÁP DỤNG MÃ GIẢM GIÁ
        [HttpPost]
        public ActionResult ApplyDiscount(string code)
        {
            var km = db.KHUYENMAIs.FirstOrDefault(x => x.MaKM == code
                                                     && DateTime.Now >= x.NgayBD
                                                     && DateTime.Now <= x.NgayKT);

            if (km != null)
            {
                Session["DiscountRate"] = km.TiLeGiam;
                Session["MaKM"] = km.MaKM;

                return Json(new
                {
                    success = true,
                    discount = km.TiLeGiam,
                    message = "Áp dụng mã giảm giá " + km.TiLeGiam + "% thành công!"
                });
            }

            return Json(new { success = false, message = "Mã giảm giá không hợp lệ hoặc đã hết hạn!" });
        }

        // ĐẶT HÀNG
        [HttpPost]
        public ActionResult Checkout(string hoTen, string sdt, string diaChi, string email, string gioiTinh, string maPT)
        {
            var cart = Session["Cart"] as List<CartItem>;
            if (cart == null || cart.Count == 0) return RedirectToAction("Index");

            var userSession = Session["KH"] as KHACHHANG;

            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    string maKH = "";
                    if (userSession != null)
                    {
                        maKH = userSession.MaKH;
                    }
                    else
                    {
                        var khachMoi = new KHACHHANG();
                        khachMoi.MaKH = "KH" + DateTime.Now.ToString("ddHHmmss");
                        khachMoi.HoTen = hoTen;
                        khachMoi.SDT = sdt;
                        khachMoi.DiaChi = diaChi;
                        khachMoi.Email = email;
                        khachMoi.GioiTinh = gioiTinh ?? "Nữ";
                        khachMoi.NgaySinh = DateTime.Now;
                        db.KHACHHANGs.Add(khachMoi);
                        db.SaveChanges();
                        maKH = khachMoi.MaKH;
                    }

                    decimal cartTotal = cart.Sum(x => x.ThanhTien);
                    string maKMUsed = Session["MaKM"] as string;

                    if (Session["DiscountRate"] != null)
                    {
                        double rate = (double)Session["DiscountRate"];
                        cartTotal = cartTotal * (decimal)(1 - (rate / 100));
                    }

                    string maHD = "HD" + DateTime.Now.ToString("ddHHmmss");
                    var hoaDon = new HOADON
                    {
                        MaHD = maHD,
                        MaKH = maKH,
                        NgayLap = DateTime.Now,
                        TongTien = cartTotal,           
                        TrangThai = "Chờ duyệt",        
                        MaKM = maKMUsed,               
                        MaNV = null
                    };
                    db.HOADONs.Add(hoaDon);

                    foreach (var item in cart)
                    {
                        var cthd = new CHITIETHOADON
                        {
                            MaHD = maHD,
                            MaSP = item.MaSP,
                            SoLuong = item.SoLuong,
                            DonGia = item.Gia,
                            ThanhTien = item.ThanhTien
                        };
                        db.CHITIETHOADONs.Add(cthd);
                    }

                    db.SaveChanges();
                    transaction.Commit();

                    Session["Cart"] = null;
                    Session["DiscountRate"] = null;
                    Session["MaKM"] = null;

                    return RedirectToAction("Success", "Cart");
                }
                catch (Exception ex)
                {
                    try { transaction.Rollback(); } catch { }

                    Exception loiThucSu = ex;
                    while (loiThucSu.InnerException != null)
                    {
                        loiThucSu = loiThucSu.InnerException;
                    }

                    string thongBaoLoi = loiThucSu.Message;
                    thongBaoLoi = thongBaoLoi.Replace("The transaction ended in the trigger. The batch has been aborted.", "").Trim();

                    if (thongBaoLoi.Contains("không đủ tồn kho") || thongBaoLoi.Contains("Số lượng tồn không đủ"))
                    {
                        TempData["Error"] = "ĐẶT HÀNG THẤT BẠI: " + thongBaoLoi;
                    }
                    else
                    {
                        TempData["Error"] = "Lỗi hệ thống: " + thongBaoLoi;
                    }

                    return RedirectToAction("Index");
                }
            }
        }

        public ActionResult Success()
        {
            return View();
        }
    }
}