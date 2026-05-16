using System;
using System.Linq;
using System.Web.Mvc;
using Nhom5_Mypham.Models; 

namespace Nhom5_Mypham.Controllers
{
    public class HomeController : Controller
    {
        private QL_MyPham_CocoonEntities db = new QL_MyPham_CocoonEntities();

        public ActionResult Index()
        {
            var listSP = db.SANPHAMs.OrderByDescending(s => s.MaSP).Take(8).ToList();

            return View(listSP);
        }

        public ActionResult About()
        {
            ViewBag.Message = "Câu chuyện thương hiệu Cocoon.";
            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Liên hệ với chúng tôi.";
            return View();
        }
    }
}