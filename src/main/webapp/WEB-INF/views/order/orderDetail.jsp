<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="../header.jsp"%>

<!-- 포트원 결제 -->
<script src="https://cdn.iamport.kr/v1/iamport.js"></script>
<!-- jQuery -->
<script type="text/javascript" src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
<!-- iamport.payment.js -->
<script type="text/javascript" src="https://cdn.iamport.kr/js/iamport.payment-1.2.0.js"></script>


<!-- orderDetail.jsp -->

<div class="delivery-wrap">
    <div class="delivery-info">
        <h2>배송지</h2>
        <form id="orderForm">
            <input type="hidden" name="cart_code" value="${cartCode}">
            <input type="hidden" name="payment_code" value="${paymentCode}">
            <input type="hidden" name="email" value="${email}">
            
            <!-- 배송지 정보 -->
            <div class="form-group">
                <label for="recipient">수령인*</label>
                <input type="text" id="recipient" name="recipient" placeholder="수령인 이름을 입력하세요" required>
            </div>
            <input type="hidden" id="recipient_name" name="recipient_name">

            <div class="form-group">
                <label>연락처*</label>
                <div class="phone-input">
                    <select id="phone1-part1" name="phone1-part1" required>
                        <option value="">선택</option>
                        <option value="010">010</option>
                    </select>
                    <input type="text" id="phone1-part2" name="phone1-part2" placeholder="-" required>
                    <input type="text" id="phone1-part3" name="phone1-part3" placeholder="-" required>
                </div>
                <input type="hidden" id="recipient_phone" name="recipient_phone">
            </div>
            <div class="form-group">
                <label>배송지 주소*</label>
                <button type="button" class="address-search" onclick="DaumPostcode()">우편번호 검색</button>
                <div id="wrap" style="display:none;"></div>
                <input type="text" id="zipcode" name="zipcode" placeholder="우편번호" readonly>
                <input type="text" id="address" name="address" placeholder="주소" readonly>
                <input type="text" id="detailed_address" name="detailed_address" placeholder="상세주소" required>
            </div>
            <input type="hidden" id="shipping_address" name="shipping_address">

            <!-- 주문상품 정보 -->
            <div class="order-items">
                <h3>주문상품 <span class="totalCount">${totalProductCount}종 ${totalProductCount}개</span>
                <button class="view-items" onclick="location.href='/cart/cartList'">주문상품 수정하기</button></h3>
                <table class="item-list">
                    <thead>
                        <tr>
                            <th> 상품 이미지 </th>
                            <th> 책 이름 </th>
                            <th> 판매가 </th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach items="${cartItems}" var="row">
                            <tr>
                                <td class="item-info">
                                    <img src="${pageContext.request.contextPath}/storage/images/${row.img}" alt="${row.book_title}" width="10%">
                                </td>
                                <td>
                                	<p class="boot-title">${row.book_title}</p>
                                </td>
                                <td>
                                    <p class="price">${row.sale_price}원</p>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>

            <!-- 할인 정보 -->
	        <div class="discount-section">
	            <h3>할인 <span class="toggle-icon">^</span></h3>
	            <div class="discount-content">
	                <div class="discount-item">
	                    <span>적립금</span>
	                    <input type="number" id="pointsInput" name="used_points" value="0" min="0" max="${userPoints}" step="10" />
	                    <button type="button" onclick="applyPoints()"> 적용 </button>
	                    <button type="button" onclick="useAllPoints()"> 전액 사용 </button>	                    
	                    <span class="available" id="availablePoints" >(보유 : ${userPoints} 원)</span>
	                </div>
	            </div>
	        </div>

            <!-- 결제수단 정보 -->
            <div class="payment-method">
                <h3>결제수단 </h3>
                <p class="total-payment">총 결제 금액 <span class="total-amount" id="finalAmount"> ${totalOrderAmount + deliveryFee} 원</span><span>(주문금액 + 배송비)</span></p>
                <div class="payment-options"> 
                    <div class="payment-option">
                        <input type="radio" name="payment_method" value="card" id="card" checked>
                        <label for="card">
                            <p>신용카드</p>
                        </label>
                    </div>
                    <div class="payment-option">
                        <input type="radio" name="payment_method" value="kakaopay" id="kakaopay">
                        <label for="kakaopay">
                            <p>카카오페이</p>
                        </label>
                    </div>
                    <div class="payment-option">
                        <input type="radio" name="payment_method" value="trans" id="trans">
                        <label for="trans">
                            <p>계좌이체</p>
                        </label>
                    </div>
                    <div class="payment-option">
                        <input type="radio" name="payment_method" value="tosspay" id="tosspay">
                        <label for="tosspay">
                            <p>토스페이</p>
                        </label>
                    </div>                                        
                </div>
            </div>

            <!-- order-aside 정보 히든 필드로 추가 -->
			<input type="hidden" id="total_order_amount" name="total_order_amount" value="${totalOrderAmount}">
            <input type="hidden" id="total_product_count" name="total_product_count" value="${totalProductCount}">
            <input type="hidden" id="total_product_amount" name="total_product_amount" value="${totalProductAmount}">
            <input type="hidden" id="total_discount_amount" name="total_discount_amount" value="0">
            <input type="hidden" id="delivery_fee" name="delivery_fee" value="${deliveryFee}">
            <input type="hidden" id="savePoints" name="expected_points" value="${expectedPoints}">

            <button type="submit" class="order-button" onclick="requestPay()"> 결제하기 </button>
        </form>
    </div>

    <!-- 결제 정보 표시 -->
    <div class="order-aside">
        <div class="customer-info">
            <h3>주문자 정보</h3>
        </div>
        <div class="payment-info">
            <h3>결제 정보</h3>
            <table>
                <tr>
                    <td>전체 주문금액</td>
                    <td id="totalAmount">${totalOrderAmount}원</td>
                </tr>
                <tr>
                    <td>상품수</td>
                    <td>${totalProductCount}개</td>
                </tr>
                <tr>
                    <td>상품금액</td>
                    <td>${totalProductAmount}원</td>
                </tr>
                <tr>
                    <td>배송비</td>
                    <td>${deliveryFee}원</td>
                </tr>
                <tr>
                    <td>예상 적립금</td>
                    <td id="expected_points">${expectedPoints}원</td>
                </tr>
                <tr>
                    <td>총 금액</td>
           			<td><strong id="finalAmount">${totalOrderAmount + deliveryFee}원</strong></td>
                </tr>
            </table>
        </div>
    </div>
</div>
<!-- Kakao 지도 API -->
<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script type="text/javascript" src="//dapi.kakao.com/v2/maps/sdk.js?appkey=1d2c6fcb1c84e26382b93490500af756&libraries=services"></script>

<script>
var IMP = window.IMP;
IMP.init("imp45135378"); // 실제 가맹점 식별코드로 변경 필요

document.addEventListener('DOMContentLoaded', function() {
    // 폼 제출 이벤트 리스너
    document.getElementById('orderForm').addEventListener('submit', function(event) {
        var recipient = document.getElementById('recipient').value;
        if (recipient.length < 2) {
            alert('수령인 이름은 최소 2글자 이상이어야 합니다.');
            event.preventDefault();
        }

        // 포인트 적용 함수 호출하여 최종 금액 및 예상 적립 포인트 업데이트
        applyPoints();

        // 사용 포인트 값 로그 출력
        var usedPoints = document.getElementById('pointsInput').value;
        console.log('Used Points:', usedPoints);
    });

    // 포인트 입력 필드의 이벤트 리스너
    document.getElementById('pointsInput').addEventListener('change', function() {
        applyPoints();
    });
    
    var element_wrap = document.getElementById('wrap');

    function foldDaumPostcode() {
        element_wrap.style.display = 'none';
    }

    function DaumPostcode() {
        var currentScroll = Math.max(document.body.scrollTop, document.documentElement.scrollTop);
        new daum.Postcode({
            oncomplete: function(data) {
                var addr = '';
                var extraAddr = '';

                if (data.userSelectedType === 'R') {
                    addr = data.roadAddress;
                } else {
                    addr = data.jibunAddress;
                }

                if (data.userSelectedType === 'R') {
                    if (data.bname !== '' && /[동|로|가]$/g.test(data.bname)) {
                        extraAddr += data.bname;
                    }
                    if (data.buildingName !== '' && data.apartment === 'Y') {
                        extraAddr += (extraAddr !== '' ? ', ' + data.buildingName : data.buildingName);
                    }
                    if (extraAddr !== '') {
                        extraAddr = ' (' + extraAddr + ')';
                    }
                    addr += extraAddr;
                }

                document.getElementById('zipcode').value = data.zonecode;
                document.getElementById('address').value = addr;

                element_wrap.style.display = 'none';
                document.body.scrollTop = currentScroll;
            },
            onresize: function(size) {
                element_wrap.style.height = size.height + 'px';
            },
            width: '100%',
            height: '100%'
        }).embed(element_wrap);

        element_wrap.style.display = 'block';
    }

    // 포인트 적용 함수
    function applyPoints() {
        // 보유 포인트를 가져옴
        const availablePoints = parseInt(document.getElementById('availablePoints').innerText);
        // 사용자가 입력한 포인트 값을 가져옴
        let pointsInput = parseInt(document.getElementById('pointsInput').value);
        // 총 주문 금액을 가져옴
        const totalOrderAmount = parseInt(document.getElementById('total_order_amount').value);
        // 배송비를 가져옴
        const deliveryFee = parseInt(document.querySelector('input[name="delivery_fee"]').value);

        // 입력된 포인트가 유효한지 확인
        if (pointsInput > availablePoints || pointsInput < 0 || pointsInput % 10 !== 0 || availablePoints < 500) {
            alert('사용할 수 없는 포인트 금액입니다. 500점 이상, 10점 단위로 사용 가능합니다.');
            return;
        }

        // 최종 책 금액 계산 (총 주문 금액  - 사용 포인트)
        const booktotalAmount = totalOrderAmount - pointsInput;
        // 최종 결제 금액 계산 (총 주문 금액 + 배송비 - 사용 포인트)
        const finalAmount = totalOrderAmount + deliveryFee - pointsInput;
        // 예상 적립 포인트 계산 (최종 결제 금액의 5%)
        const expectedPoints = Math.floor(booktotalAmount * 0.05);

        // 계산된 최종 결제 금액과 예상 적립 포인트를 화면에 표시
        document.getElementById('finalAmount').innerText = finalAmount + '원';
        document.getElementById('totalAmount').innerText = finalAmount + '원';
        document.getElementById('expected_points').innerText = expectedPoints + '원';
        
        // 적립 포인트를 숨겨진 필드에 저장
        document.getElementById('savePoints').value = expectedPoints;
    }

    // 함수 정의를 global scope로 노출
    window.foldDaumPostcode = foldDaumPostcode;
    window.DaumPostcode = DaumPostcode;
    window.applyPoints = applyPoints;
    window.useAllPoints = useAllPoints;
});

// 포인트 전액 사용 함수
function useAllPoints() {
    // 보유 포인트를 가져옴
    const availablePointsElement = document.getElementById('availablePoints');
    if (!availablePointsElement) {
        console.error('availablePoints 요소를 찾을 수 없습니다.');
        return;
    }
    const availablePoints = parseInt(availablePointsElement.innerText.replace(/[^\d]/g, ''));
    // 포인트 입력 필드에 보유 포인트 전액을 입력
    document.getElementById('pointsInput').value = availablePoints;
    applyPoints(); // 전액 사용 후 적용 함수 호출
}

function requestPay() {
    console.log("requestPay function called");

    var paymentMethod = document.querySelector('input[name="payment_method"]:checked').value;
    var amount = parseInt(document.getElementById('finalAmount').innerText.replace(/[^\d]/g, ''));
    var name = document.getElementById('recipient').value;
    var phone = document.getElementById('recipient_phone').value;
    var email = document.getElementById('email').value;
    
    // selectedItems 호출
    var selectedItems = getSelectedItems();

    console.log("Payment Method:", paymentMethod);
    console.log("Amount:", amount);
    console.log("Name:", name);
    console.log("Phone:", phone);
    console.log("Email:", email);
    console.log("Selected Items:", selectedItems);

    var today = new Date();
    var merchant_uid = "IMP" + today.getHours() + today.getMinutes() + today.getSeconds() + today.getMilliseconds();

    var pg;
    switch(paymentMethod) {
        case 'kakaopay':
            pg = 'kakaopay.TC0ONETIME';
            break;
        case 'tosspay':
            pg = 'tosspay';
            break;
        case 'trans':
            pg = 'html5_inicis';
            break;
        case 'card':
        default:
            pg = 'html5_inicis';
    }

    IMP.request_pay({
        pg: pg,
        pay_method: paymentMethod === 'trans' ? 'trans' : 'card',
        merchant_uid: merchant_uid,
        name: '상품 결제',
        amount: amount,
        buyer_name: name,
        buyer_tel: phone,
        buyer_email: email,
        custom_data: {selectedItems: selectedItems}  // selectedItems를 custom_data로 전달
    }, function (rsp) {
        if (rsp.success) {
            alert('결제가 완료되었습니다.');
            // 결제 성공 시 추가 데이터를 폼에 포함
            var form = document.getElementById('orderForm');
            
            var hiddenField = document.createElement('input');
            hiddenField.type = 'hidden';
            hiddenField.name = 'imp_uid';
            hiddenField.value = rsp.imp_uid;
            form.appendChild(hiddenField);
            form.submit();
        } else {
            alert('결제에 실패하였습니다. ' + rsp.error_msg);
        }
    });
}

function getSelectedItems() {
    // 체크박스를 사용하여 선택된 항목의 ID를 배열로 반환
    const checkboxes = document.querySelectorAll('input[name="selected"]:checked');
    return Array.from(checkboxes).map(checkbox => checkbox.value);
}

</script>

<style>
.delivery-wrap {
    display: flex;
    max-width: 1000px;
    margin: 15px auto;
    gap: 15px;
}

.delivery-info {
    flex: 7;
    background-color: #ffffff;
    padding: 20px;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.order-aside {
    flex: 3;
    background-color: #ffffff;
    padding: 20px;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    height: fit-content;
}

h2 {
    font-size: 16px;
    margin-bottom: 15px;
}

.form-group {
    margin-bottom: 15px;
}

.form-group label {
    display: block;
    margin-bottom: 4px;
    font-weight: bold;
    font-size: 12px;
}

.radio-group {
    display: flex;
    gap: 15px;
}

.radio-group label {
    display: flex;
    align-items: center;
    gap: 4px;
}

input[type="text"], select {
    width: 100%;
    padding: 6px 8px;
    border: 1px solid #ddd;
    border-radius: 3px;
    font-size: 12px;
}

.phone-input {
    display: flex;
    gap: 8px;
}

.phone-input select {
    width: 70px;
}

.phone-input input {
    flex: 1;
}

.address-search {
    background-color: #f8f8f8;
    border: 1px solid #ddd;
    padding: 6px 12px;
    border-radius: 3px;
    cursor: pointer;
    margin-bottom: 8px;
    font-size: 12px;
}

.delivery-memo {
    margin-top: 20px;
}

.customer-info, .payment-info {
    margin-bottom: 20px;
}

.customer-info h3, .payment-info h3 {
    font-size: 14px;
    margin-bottom: 10px;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12px;
    font-size: 12px;
}

td {
    padding: 6px 0;
}

td:last-child {
    text-align: right;
}

.green-text {
    color: #4CAF50;
    font-size: 11px;
    margin-top: 12px;
}

.order-button {
    width: 100%;
    padding: 12px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 3px;
    cursor: pointer;
    font-size: 14px;
    font-weight: bold;
}

.checkbox-label, .radio-label {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-top: 4px;
    font-size: 12px;
}

.discount-section, .payment-method {
    border: 1px solid #ddd;
    border-radius: 4px;
    margin-top: 20px;
    overflow: hidden;
}

.discount-section h3, .payment-method h3 {
    background-color: #f8f8f8;
    padding: 10px 15px;
    margin: 0;
    font-size: 14px;
    border-bottom: 1px solid #ddd;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.toggle-icon, .check-icon {
    font-size: 12px;
    color: #888;
}

.discount-content {
    padding: 15px;
}

.no-discount {
    color: #888;
    margin-bottom: 10px;
}

.discount-item {
    display: flex;
    align-items: center;
    margin-bottom: 10px;
}

.discount-item span {
    width: 80px;
}

.discount-item input {
    width: 100px;
    margin-right: 10px;
}

.discount-item button {
    background-color: #f8f8f8;
    border: 1px solid #ddd;
    padding: 5px 10px;
    border-radius: 3px;
    font-size: 12px;
    margin-right: 10px;
}

.available {
    color: #888;
    font-size: 12px;
}

.discount-note {
    font-size: 12px;
    color: #888;
    margin-top: 10px;
}

.payment-method {
    padding-bottom: 15px;
}

.total-payment {
    padding: 15px;
    font-weight: bold;
    border-bottom: 1px solid #ddd;
}

.total-amount {
    color: #e74c3c;
    font-size: 18px;
}

.payment-options {
    display: flex;
    justify-content: space-around;
    padding: 15px;
}

.payment-option {
    text-align: center;
}

.payment-option img {
    width: 80px;
    height: 40px;
    object-fit: contain;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 5px;
}

.payment-option p {
    margin-top: 5px;
    font-size: 12px;
}

.payment-note {
    padding: 0 15px;
    font-size: 12px;
    color: #4CAF50;
}
</style>

<%@ include file="../footer.jsp"%>
